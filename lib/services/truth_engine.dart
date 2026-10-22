import 'dart:math' as math;

import '../models/face_frame.dart';
import '../models/session.dart';
import '../models/signals.dart';

enum ScanPhase { calibrating, analyzing, finished }

class EngineSnapshot {
  const EngineSnapshot({
    required this.phase,
    required this.calibrationProgress,
    required this.coherence,
    required this.confidence,
    required this.signals,
    required this.validFrames,
    required this.faceCoverage,
    required this.facePresent,
    required this.hint,
    required this.elapsedSec,
    required this.blinkRate,
    required this.analysisReady,
  });

  final ScanPhase phase;
  final double calibrationProgress;
  final double coherence;
  final double confidence;
  final List<SignalReading> signals;
  final int validFrames;
  final double faceCoverage;
  final bool facePresent;
  final String hint;
  final double elapsedSec;
  final double blinkRate;
  final bool analysisReady;

  static EngineSnapshot initial() => const EngineSnapshot(
    phase: ScanPhase.calibrating,
    calibrationProgress: 0,
    coherence: 100,
    confidence: 0,
    signals: [],
    validFrames: 0,
    faceCoverage: 0,
    facePresent: false,
    hint: 'Coloca tu rostro frente a la cámara',
    elapsedSec: 0,
    blinkRate: 0,
    analysisReady: false,
  );
}

class SessionSummary {
  const SessionSummary({
    required this.score,
    required this.peakInconsistency,
    required this.confidence,
    required this.durationSec,
    required this.frames,
    required this.faceCoverage,
    required this.signals,
    required this.timeline,
    required this.blinkRate,
  });

  final double score;
  final double peakInconsistency;
  final double confidence;
  final double durationSec;
  final int frames;
  final double faceCoverage;
  final List<SignalReading> signals;
  final List<double> timeline;
  final double blinkRate;

  Verdict get verdict => Verdict.fromScore(score);

  Session toSession({
    required String id,
    required DateTime startedAt,
    required String subject,
    required String notes,
    required int questions,
  }) {
    return Session(
      id: id,
      startedAt: startedAt,
      durationSec: durationSec,
      subject: subject,
      score: score,
      verdict: verdict,
      confidence: confidence,
      peakInconsistency: peakInconsistency,
      blinkRate: blinkRate,
      frames: frames,
      faceCoverage: faceCoverage,
      signals: signals,
      timeline: timeline,
      notes: notes,
      questions: questions,
    );
  }
}

class TruthEngine {
  TruthEngine({
    this.sensitivity = 1.0,
    this.calibrationMs = 10000,
    this.windowMs = 4000,
  });

  final double sensitivity;
  final int calibrationMs;
  final int windowMs;

  final List<_Feature> _calibration = [];
  final List<_Feature> _window = [];
  final List<double> _analysisCoherence = [];
  final List<double> _timeline = [];
  final List<int> _blinks = [];
  final Map<SignalKind, double> _signalEma = {
    for (final kind in SignalKind.values) kind: 0,
  };

  _Baseline? _baseline;
  ScanPhase _phase = ScanPhase.calibrating;
  EngineSnapshot _snapshot = EngineSnapshot.initial();

  int? _lastCalibrationFaceMs;
  int _calibrationElapsedMs = 0;
  int? _analysisStartMs;
  int _lastFrameMs = 0;
  int _lastSnapshotMs = 0;
  int _totalFrames = 0;
  int _faceFrames = 0;
  int _validFrames = 0;
  int _baselineFrames = 0;
  int _calibrationBlinks = 0;
  bool _eyesClosed = false;
  double _coherence = 100;
  double _confidence = 0;
  double _lastBlinkRate = 0;
  int _timelineBucketMs = 0;

  EngineSnapshot get snapshot => _snapshot;

  List<SignalReading> get liveSignals => _snapshot.signals;

  void ingest(FaceFrame frame) {
    _totalFrames++;
    _lastFrameMs = frame.ms;
    if (frame.faceDetected) {
      _faceFrames++;
    }

    if (_phase == ScanPhase.finished) return;

    if (!frame.faceDetected) {
      _snapshot = _buildSnapshot(
        facePresent: false,
        hint: 'No detecto tu rostro. Acércate y busca luz frontal.',
      );
      return;
    }

    _validFrames++;
    final feature = _Feature.fromFrame(frame);
    _trackBlink(feature, frame.ms);

    if (_phase == ScanPhase.calibrating) {
      _calibration.add(feature);
      if (_lastCalibrationFaceMs != null &&
          frame.ms - _lastCalibrationFaceMs! < 700) {
        _calibrationElapsedMs += frame.ms - _lastCalibrationFaceMs!;
      }
      _lastCalibrationFaceMs = frame.ms;

      final progress = (_calibrationElapsedMs / calibrationMs).clamp(0.0, 1.0);
      if (progress >= 1 && _calibration.length >= 40) {
        _startAnalysis(frame.ms);
      } else {
        _snapshot = _buildSnapshot(
          facePresent: true,
          hint: 'Mantén un rostro neutro y mira al lente',
        );
      }
      return;
    }

    _window.add(feature);
    final cutoff = frame.ms - windowMs;
    while (_window.isNotEmpty && _window.first.ms < cutoff) {
      _window.removeAt(0);
    }

    if (_baseline != null && _window.length >= 5) {
      _updateSignals(frame.ms);
    }

    _snapshot = _buildSnapshot(facePresent: true);
  }

  void _startAnalysis(int ms) {
    _baseline = _Baseline.fromFeatures(
      _calibration,
      _blinkRateDuringCalibration(),
    );
    _baselineFrames = _calibration.length;
    _phase = ScanPhase.analyzing;
    _analysisStartMs = ms;
    _calibration.clear();
    _window.clear();
    _coherence = 100;
    _snapshot = _buildSnapshot(facePresent: true);
  }

  double _blinkRateDuringCalibration() {
    final seconds = math.max(_calibrationElapsedMs / 1000, 4);
    final rate = _calibrationBlinks * 60 / seconds;
    if (_calibrationBlinks < 2) return 15;
    return rate.clamp(4, 40);
  }

  void _trackBlink(_Feature feature, int ms) {
    final open = feature.eyeOpen;
    if (open < 0.35) {
      _eyesClosed = true;
    } else if (_eyesClosed && open > 0.55) {
      _eyesClosed = false;
      _blinks.add(ms);
      if (_phase == ScanPhase.calibrating) _calibrationBlinks++;
      if (_blinks.length > 80) _blinks.removeAt(0);
    }
  }

  void _updateSignals(int ms) {
    final baseline = _baseline!;
    final stats = _WindowStats.fromFeatures(_window);
    final now = ms;

    final lipDev = _mix(
      _dev(stats.lipMean, baseline.lipMean, baseline.lipStd, 0.015),
      _excess(stats.lipStd, baseline.lipStd, 0.004),
      0.72,
    );
    final blink = _blinkMetrics(now);
    _lastBlinkRate = blink.rate;
    final blinkDev = _mix(
      _devOneSided(blink.rate, baseline.blinkRate, 8),
      _excess(blink.irregularity, 0.45, 0.25),
      0.7,
    );
    final gazeOut = _window.where((f) => f.gaze > 13).length / _window.length;
    final gazeDev = _mix3(
      _dev(stats.gazeMean, baseline.gazeMean, baseline.gazeStd, 3),
      _excess(stats.gazeStd, baseline.gazeStd, 2),
      gazeOut * 0.9,
      0.45,
      0.3,
    );
    final headDev = _mix3(
      _excess(stats.yawStd, baseline.yawStd, 1.2),
      _excess(stats.pitchStd, baseline.pitchStd, 1.2),
      _dev(stats.pitchMean, baseline.pitchMean, baseline.pitchStd, 3),
      0.4,
      0.4,
    );
    final asymDev = _mix(
      _dev(stats.asymMean, baseline.asymMean, baseline.asymStd, 0.012),
      _excess(stats.asymStd, baseline.asymStd, 0.01),
      0.7,
    );
    final expressionDev = _mix(
      _dev(stats.smileMean, baseline.smileMean, baseline.smileStd, 0.1),
      _excess(stats.smileStd, baseline.smileStd, 0.03),
      0.65,
    );

    final raw = <SignalKind, double>{
      SignalKind.lips: lipDev,
      SignalKind.blink: blinkDev,
      SignalKind.gaze: gazeDev,
      SignalKind.head: headDev,
      SignalKind.asymmetry: asymDev,
      SignalKind.expression: expressionDev,
    };

    var weighted = 0.0;
    for (final kind in SignalKind.values) {
      final target = (raw[kind]! * sensitivity).clamp(0.0, 1.0);
      final previous = _signalEma[kind]!;
      final smoothed = previous + (target - previous) * 0.28;
      _signalEma[kind] = smoothed;
      weighted += smoothed * kind.weight;
    }

    weighted = (weighted * 1.45).clamp(0.0, 1.0);
    final target = 100 * (1 - weighted);
    _coherence += (target - _coherence) * 0.16;

    final analysisElapsed = math.max(
      (ms - (_analysisStartMs ?? ms)) / 1000,
      0.001,
    );
    _confidence = _computeConfidence(analysisElapsed);

    if (now - _lastSnapshotMs >= 450) {
      _lastSnapshotMs = now;
      _analysisCoherence.add(_coherence);
      if (now - _timelineBucketMs >= 650 || _timeline.isEmpty) {
        _timelineBucketMs = now;
        _timeline.add(_coherence);
        if (_timeline.length > 90) _timeline.removeAt(0);
      }
      if (_analysisCoherence.length > 600) _analysisCoherence.removeAt(0);
    }
  }

  double _computeConfidence(double elapsed) {
    final coverage = _totalFrames == 0 ? 0.0 : _faceFrames / _totalFrames;
    final density = (_validFrames / math.max(elapsed * 3, 1)).clamp(0.0, 1.0);
    final baselineQuality = _baseline == null
        ? 0.0
        : (_baselineFrames >= 40 ? 1.0 : 0.5);
    return (coverage * 0.55 + density * 0.25 + baselineQuality * 0.2).clamp(
      0.0,
      1.0,
    );
  }

  _BlinkMetrics _blinkMetrics(int now) {
    final spanMs = math.min(
      math.max(now - (_analysisStartMs ?? now), 8000),
      30000,
    );
    final recent = _blinks
        .where(
          (time) => time >= now - spanMs && time >= (_analysisStartMs ?? 0),
        )
        .toList();
    final rate = recent.length * 60000 / spanMs;
    double irregularity = 0;
    if (recent.length >= 3) {
      final intervals = <double>[];
      for (var i = 1; i < recent.length; i++) {
        intervals.add((recent[i] - recent[i - 1]).toDouble());
      }
      final mean = intervals.reduce((a, b) => a + b) / intervals.length;
      if (mean > 0) {
        final variance =
            intervals
                .map((value) => math.pow(value - mean, 2))
                .reduce((a, b) => a + b) /
            intervals.length;
        irregularity = (math.sqrt(variance) / mean).clamp(0.0, 2.0);
      }
    }
    return _BlinkMetrics(rate: rate.clamp(0, 60), irregularity: irregularity);
  }

  EngineSnapshot _buildSnapshot({required bool facePresent, String? hint}) {
    final seconds = _phase == ScanPhase.analyzing && _analysisStartMs != null
        ? (_lastFrameMs - _analysisStartMs!) / 1000
        : _calibrationElapsedMs / 1000;
    final stats = _window.length >= 3
        ? _WindowStats.fromFeatures(_window)
        : null;
    final signals = <SignalReading>[
      SignalReading(
        kind: SignalKind.lips,
        deviation: _signalEma[SignalKind.lips]!,
        detail: stats == null
            ? '—'
            : '${(stats.lipMean * 100).toStringAsFixed(1)}% apertura',
      ),
      SignalReading(
        kind: SignalKind.blink,
        deviation: _signalEma[SignalKind.blink]!,
        detail: _lastBlinkRate > 0 ? '${_lastBlinkRate.round()} /min' : '—',
      ),
      SignalReading(
        kind: SignalKind.gaze,
        deviation: _signalEma[SignalKind.gaze]!,
        detail: stats == null
            ? '—'
            : '${stats.gazeMean.toStringAsFixed(0)}° desvío',
      ),
      SignalReading(
        kind: SignalKind.head,
        deviation: _signalEma[SignalKind.head]!,
        detail: stats == null
            ? '—'
            : '${(stats.yawStd + stats.pitchStd).toStringAsFixed(1)}° var.',
      ),
      SignalReading(
        kind: SignalKind.asymmetry,
        deviation: _signalEma[SignalKind.asymmetry]!,
        detail: stats == null
            ? '—'
            : '${(stats.asymMean * 100).toStringAsFixed(1)}%',
      ),
      SignalReading(
        kind: SignalKind.expression,
        deviation: _signalEma[SignalKind.expression]!,
        detail: stats == null
            ? '—'
            : '${(stats.smileMean * 100).toStringAsFixed(0)}% sonrisa',
      ),
    ];

    final elapsed = seconds.clamp(0.0, 9999.0);
    final coverage = _totalFrames == 0 ? 0.0 : _faceFrames / _totalFrames;
    final defaultHint = _phase == ScanPhase.calibrating
        ? 'Mantén un rostro neutro y mira al lente'
        : _coherence > 80
        ? 'Habla con naturalidad y sostén la mirada'
        : 'Observa las microseñales en tiempo real';
    final analysisReady = _phase != ScanPhase.calibrating;

    return EngineSnapshot(
      phase: _phase,
      calibrationProgress: (_calibrationElapsedMs / calibrationMs).clamp(
        0.0,
        1.0,
      ),
      coherence: _coherence.clamp(0.0, 100.0),
      confidence: analysisReady ? _confidence : 0,
      signals: _phase == ScanPhase.calibrating ? const [] : signals,
      validFrames: _validFrames,
      faceCoverage: coverage,
      facePresent: facePresent,
      hint: hint ?? defaultHint,
      elapsedSec: elapsed,
      blinkRate: _lastBlinkRate,
      analysisReady: analysisReady,
    );
  }

  bool get canFinish => _phase == ScanPhase.analyzing;

  SessionSummary finish() {
    _phase = ScanPhase.finished;
    final scores = _analysisCoherence.isEmpty
        ? <double>[_coherence]
        : _analysisCoherence;
    final average = scores.reduce((a, b) => a + b) / scores.length;
    final minimum = scores.reduce(math.min);
    final elapsed = _analysisStartMs == null
        ? 0.0
        : math.max((_lastFrameMs - _analysisStartMs!) / 1000, 1.0);

    final signals = <SignalReading>[];
    for (final kind in SignalKind.values) {
      final matching = _snapshot.signals
          .where((reading) => reading.kind == kind)
          .toList();
      signals.add(
        SignalReading(
          kind: kind,
          deviation: _signalEma[kind]!,
          detail: matching.isEmpty ? '—' : matching.first.detail,
        ),
      );
    }

    final summary = SessionSummary(
      score: average.clamp(0.0, 100.0),
      peakInconsistency: (100 - minimum).clamp(0.0, 100.0),
      confidence: _confidence,
      durationSec: elapsed,
      frames: _validFrames,
      faceCoverage: _totalFrames == 0 ? 0 : _faceFrames / _totalFrames,
      signals: signals,
      timeline: _timeline.isEmpty ? <double>[_coherence] : List.of(_timeline),
      blinkRate: _lastBlinkRate,
    );
    _snapshot = _buildSnapshot(facePresent: true, hint: 'Análisis completado');
    return summary;
  }

  void reset() {
    _calibration.clear();
    _window.clear();
    _analysisCoherence.clear();
    _timeline.clear();
    _blinks.clear();
    for (final kind in SignalKind.values) {
      _signalEma[kind] = 0;
    }
    _baseline = null;
    _phase = ScanPhase.calibrating;
    _snapshot = EngineSnapshot.initial();
    _lastCalibrationFaceMs = null;
    _calibrationElapsedMs = 0;
    _analysisStartMs = null;
    _lastFrameMs = 0;
    _lastSnapshotMs = 0;
    _totalFrames = 0;
    _faceFrames = 0;
    _validFrames = 0;
    _calibrationBlinks = 0;
    _eyesClosed = false;
    _coherence = 100;
    _confidence = 0;
    _lastBlinkRate = 0;
    _timelineBucketMs = 0;
  }
}

class _Feature {
  const _Feature({
    required this.ms,
    required this.lip,
    required this.eyeOpen,
    required this.gaze,
    required this.yaw,
    required this.pitch,
    required this.asym,
    required this.smile,
  });

  final int ms;
  final double lip;
  final double eyeOpen;
  final double gaze;
  final double yaw;
  final double pitch;
  final double asym;
  final double smile;

  factory _Feature.fromFrame(FaceFrame frame) {
    final yaw = frame.yaw ?? 0;
    final pitch = frame.pitch ?? 0;
    final eye = frame.eyeOpen ?? 0.82;
    final asym = (frame.cheekAsymmetry ?? 0) + (frame.eyeAsymmetry ?? 0) * 0.4;
    return _Feature(
      ms: frame.ms,
      lip: frame.mouthAspect ?? 0.16,
      eyeOpen: eye,
      gaze: math.sqrt(yaw * yaw + pitch * pitch),
      yaw: yaw,
      pitch: pitch,
      asym: asym,
      smile: frame.smiling ?? 0.05,
    );
  }
}

class _WindowStats {
  const _WindowStats({
    required this.lipMean,
    required this.lipStd,
    required this.gazeMean,
    required this.gazeStd,
    required this.yawStd,
    required this.pitchMean,
    required this.pitchStd,
    required this.asymMean,
    required this.asymStd,
    required this.smileMean,
    required this.smileStd,
  });

  final double lipMean;
  final double lipStd;
  final double gazeMean;
  final double gazeStd;
  final double yawStd;
  final double pitchMean;
  final double pitchStd;
  final double asymMean;
  final double asymStd;
  final double smileMean;
  final double smileStd;

  factory _WindowStats.fromFeatures(List<_Feature> features) {
    return _WindowStats(
      lipMean: _mean(features.map((f) => f.lip)),
      lipStd: _std(features.map((f) => f.lip)),
      gazeMean: _mean(features.map((f) => f.gaze)),
      gazeStd: _std(features.map((f) => f.gaze)),
      yawStd: _std(features.map((f) => f.yaw)),
      pitchMean: _mean(features.map((f) => f.pitch)),
      pitchStd: _std(features.map((f) => f.pitch)),
      asymMean: _mean(features.map((f) => f.asym)),
      asymStd: _std(features.map((f) => f.asym)),
      smileMean: _mean(features.map((f) => f.smile)),
      smileStd: _std(features.map((f) => f.smile)),
    );
  }
}

class _Baseline {
  const _Baseline({
    required this.lipMean,
    required this.lipStd,
    required this.gazeMean,
    required this.gazeStd,
    required this.yawStd,
    required this.pitchMean,
    required this.pitchStd,
    required this.asymMean,
    required this.asymStd,
    required this.smileMean,
    required this.smileStd,
    required this.blinkRate,
  });

  final double lipMean;
  final double lipStd;
  final double gazeMean;
  final double gazeStd;
  final double yawStd;
  final double pitchMean;
  final double pitchStd;
  final double asymMean;
  final double asymStd;
  final double smileMean;
  final double smileStd;
  final double blinkRate;

  factory _Baseline.fromFeatures(List<_Feature> features, double blinkRate) {
    final stats = _WindowStats.fromFeatures(features);
    return _Baseline(
      lipMean: stats.lipMean,
      lipStd: stats.lipStd,
      gazeMean: stats.gazeMean,
      gazeStd: stats.gazeStd,
      yawStd: stats.yawStd,
      pitchMean: stats.pitchMean,
      pitchStd: stats.pitchStd,
      asymMean: stats.asymMean,
      asymStd: stats.asymStd,
      smileMean: stats.smileMean,
      smileStd: stats.smileStd,
      blinkRate: blinkRate,
    );
  }
}

class _BlinkMetrics {
  const _BlinkMetrics({required this.rate, required this.irregularity});

  final double rate;
  final double irregularity;
}

double _mean(Iterable<double> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}

double _std(Iterable<double> values) {
  final list = values.toList();
  if (list.length < 2) return 0;
  final mean = _mean(list);
  final variance =
      list.map((value) => math.pow(value - mean, 2)).reduce((a, b) => a + b) /
      list.length;
  return math.sqrt(variance);
}

/// Desviación normalizada de un valor respecto a la media de la línea base.
double _dev(double value, double mean, double std, double floor) {
  final scale = math.max(std * 2.5, floor);
  return ((value - mean).abs() / scale).clamp(0.0, 1.0);
}

/// Exceso de variabilidad respecto a la línea base (0 = igual o menor).
double _excess(double value, double baseline, double floor) {
  final deadZone = math.max(baseline * 1.15, floor);
  final span = math.max(baseline * 2.2, floor * 2.5);
  return ((value - deadZone) / span).clamp(0.0, 1.0);
}

/// Aumento de un valor respecto a la línea base (no penaliza valores menores).
double _devOneSided(double value, double baseline, double floor) {
  final span = math.max(baseline * 0.7, floor);
  return ((value - baseline * 1.15) / span).clamp(0.0, 1.0);
}

double _mix(double a, double b, double weightA) {
  return (a * weightA + b * (1 - weightA)).clamp(0.0, 1.0);
}

double _mix3(double a, double b, double c, double wa, double wb) {
  return (a * wa + b * wb + c * (1 - wa - wb)).clamp(0.0, 1.0);
}
