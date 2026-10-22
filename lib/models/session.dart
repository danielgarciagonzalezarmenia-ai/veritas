import 'signals.dart';

class Session {
  const Session({
    required this.id,
    required this.startedAt,
    required this.durationSec,
    required this.subject,
    required this.score,
    required this.verdict,
    required this.confidence,
    required this.peakInconsistency,
    required this.blinkRate,
    required this.frames,
    required this.faceCoverage,
    required this.signals,
    required this.timeline,
    this.notes = '',
    this.questions = 0,
  });

  final String id;
  final DateTime startedAt;
  final double durationSec;
  final String subject;
  final double score;
  final Verdict verdict;
  final double confidence;
  final double peakInconsistency;
  final double blinkRate;
  final int frames;
  final double faceCoverage;
  final List<SignalReading> signals;
  final List<double> timeline;
  final String notes;
  final int questions;

  Session copyWith({String? subject, String? notes}) {
    return Session(
      id: id,
      startedAt: startedAt,
      durationSec: durationSec,
      subject: subject ?? this.subject,
      score: score,
      verdict: verdict,
      confidence: confidence,
      peakInconsistency: peakInconsistency,
      blinkRate: blinkRate,
      frames: frames,
      faceCoverage: faceCoverage,
      signals: signals,
      timeline: timeline,
      notes: notes ?? this.notes,
      questions: questions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'durationSec': durationSec,
    'subject': subject,
    'score': score,
    'verdict': verdict.name,
    'confidence': confidence,
    'peakInconsistency': peakInconsistency,
    'blinkRate': blinkRate,
    'frames': frames,
    'faceCoverage': faceCoverage,
    'signals': signals.map((signal) => signal.toJson()).toList(),
    'timeline': timeline,
    'notes': notes,
    'questions': questions,
  };

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      durationSec: (json['durationSec'] as num? ?? 0).toDouble(),
      subject: json['subject'] as String? ?? 'Sin nombre',
      score: (json['score'] as num? ?? 0).toDouble(),
      verdict: Verdict.values.firstWhere(
        (verdict) => verdict.name == json['verdict'],
        orElse: () =>
            Verdict.fromScore((json['score'] as num? ?? 0).toDouble()),
      ),
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
      peakInconsistency: (json['peakInconsistency'] as num? ?? 0).toDouble(),
      blinkRate: (json['blinkRate'] as num? ?? 0).toDouble(),
      frames: (json['frames'] as num? ?? 0).toInt(),
      faceCoverage: (json['faceCoverage'] as num? ?? 0).toDouble(),
      signals: (json['signals'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                SignalReading.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      timeline: (json['timeline'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toDouble())
          .toList(),
      notes: json['notes'] as String? ?? '',
      questions: (json['questions'] as num? ?? 0).toInt(),
    );
  }
}
