import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:veritas/models/face_frame.dart';
import 'package:veritas/models/signals.dart';
import 'package:veritas/services/truth_engine.dart';

FaceFrame _frame(
  int ms, {
  bool detected = true,
  double yaw = 0,
  double pitch = 0,
  double roll = 0,
  double mouth = 0.16,
  double eye = 0.86,
  double smile = 0.04,
  double asym = 0.01,
}) {
  return FaceFrame(
    timestamp: Duration(milliseconds: ms),
    faceDetected: detected,
    yaw: yaw,
    pitch: pitch,
    roll: roll,
    mouthAspect: mouth,
    leftEyeOpen: eye,
    rightEyeOpen: eye,
    smiling: smile,
    cheekAsymmetry: asym,
    faceSpan: 0.55,
  );
}

TruthEngine _engine() => TruthEngine(calibrationMs: 2000, windowMs: 3000);

void _calibrate(TruthEngine engine, {int start = 0, int count = 70}) {
  for (var i = 0; i < count; i++) {
    final t = start + i * 100;
    engine.ingest(
      _frame(t, yaw: math.sin(i / 7) * 1.5, pitch: math.cos(i / 9) * 1.2),
    );
  }
}

void main() {
  test('la calibración requiere rostro y avanza con frames válidos', () {
    final engine = _engine();
    for (var i = 0; i < 40; i++) {
      engine.ingest(_frame(i * 100, detected: false));
    }
    expect(engine.snapshot.phase, ScanPhase.calibrating);
    expect(engine.snapshot.calibrationProgress, lessThan(0.5));
    expect(engine.snapshot.faceCoverage, 0);
  });

  test('al terminar la calibración pasa a análisis', () {
    final engine = _engine();
    _calibrate(engine);
    engine.ingest(_frame(7200));
    expect(engine.snapshot.phase, ScanPhase.analyzing);
    expect(engine.snapshot.analysisReady, isTrue);
    expect(engine.snapshot.signals.length, 6);
    expect(engine.snapshot.coherence, greaterThan(90));
  });

  test('un comportamiento neutro mantiene alta coherencia', () {
    final engine = _engine();
    _calibrate(engine);
    for (var i = 0; i < 120; i++) {
      final t = 7200 + i * 100;
      engine.ingest(
        _frame(
          t,
          yaw: math.sin(i / 6) * 1.2,
          pitch: math.cos(i / 8) * 1.0,
          mouth: 0.16 + math.sin(i / 10) * 0.005,
          eye: 0.86,
          smile: 0.05,
        ),
      );
    }
    expect(engine.snapshot.coherence, greaterThan(85));
  });

  test('desviaciones sostenidas reducen la coherencia', () {
    final engine = _engine();
    _calibrate(engine);
    for (var i = 0; i < 160; i++) {
      final t = 7200 + i * 100;
      final blink = i % 9 == 0;
      engine.ingest(
        _frame(
          t,
          yaw: math.sin(i / 2) * 18,
          pitch: math.cos(i / 2) * 12,
          mouth: 0.05,
          eye: blink ? 0.1 : 0.9,
          smile: i.isEven ? 0.0 : 0.55,
          asym: 0.09,
        ),
      );
    }
    final stressed = engine.snapshot;
    expect(stressed.coherence, lessThan(75));
    final gaze = stressed.signals
        .firstWhere((signal) => signal.kind == SignalKind.gaze)
        .deviation;
    expect(gaze, greaterThan(0.2));
  });

  test('finish genera un resumen consistente', () {
    final engine = _engine();
    _calibrate(engine);
    for (var i = 0; i < 80; i++) {
      engine.ingest(_frame(7200 + i * 100, yaw: math.sin(i / 5) * 2));
    }
    final summary = engine.finish();
    expect(summary.score, inInclusiveRange(0, 100));
    expect(summary.timeline, isNotEmpty);
    expect(summary.signals.length, 6);
    expect(summary.durationSec, greaterThan(0));
    expect(summary.verdict, Verdict.fromScore(summary.score));
  });
}
