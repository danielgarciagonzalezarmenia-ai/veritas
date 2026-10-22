enum SignalKind { lips, blink, gaze, head, asymmetry, expression }

extension SignalKindInfo on SignalKind {
  String get key => name;

  String get label {
    switch (this) {
      case SignalKind.lips:
        return 'Tensión labial';
      case SignalKind.blink:
        return 'Parpadeo';
      case SignalKind.gaze:
        return 'Mirada';
      case SignalKind.head:
        return 'Microgestos';
      case SignalKind.asymmetry:
        return 'Asimetría facial';
      case SignalKind.expression:
        return 'Expresión';
    }
  }

  String get shortLabel {
    switch (this) {
      case SignalKind.lips:
        return 'Labios';
      case SignalKind.blink:
        return 'Parpadeo';
      case SignalKind.gaze:
        return 'Mirada';
      case SignalKind.head:
        return 'Cabeza';
      case SignalKind.asymmetry:
        return 'Simetría';
      case SignalKind.expression:
        return 'Gestos';
    }
  }

  String get description {
    switch (this) {
      case SignalKind.lips:
        return 'Micro-compresiones y aperturas súbitas de la boca.';
      case SignalKind.blink:
        return 'Frecuencia e irregularidad del parpadeo respecto a tu línea base.';
      case SignalKind.gaze:
        return 'Desviaciones de la mirada y del eje de la cabeza.';
      case SignalKind.head:
        return 'Micro-nodos, inclinaciones y temblor cefálico.';
      case SignalKind.asymmetry:
        return 'Cambios de simetría entre ambos lados del rostro.';
      case SignalKind.expression:
        return 'Fluctuaciones de sonrisa y contención emocional.';
    }
  }

  double get weight {
    switch (this) {
      case SignalKind.lips:
        return 0.20;
      case SignalKind.blink:
        return 0.15;
      case SignalKind.gaze:
        return 0.22;
      case SignalKind.head:
        return 0.17;
      case SignalKind.asymmetry:
        return 0.14;
      case SignalKind.expression:
        return 0.12;
    }
  }

  static SignalKind fromKey(String key) {
    return SignalKind.values.firstWhere(
      (kind) => kind.key == key,
      orElse: () => SignalKind.gaze,
    );
  }
}

class SignalReading {
  const SignalReading({
    required this.kind,
    required this.deviation,
    required this.detail,
  });

  final SignalKind kind;

  /// 0 = igual que la línea base, 1 = desviación máxima.
  final double deviation;
  final String detail;

  Map<String, dynamic> toJson() => {
    'kind': kind.key,
    'deviation': deviation,
    'detail': detail,
  };

  factory SignalReading.fromJson(Map<String, dynamic> json) {
    return SignalReading(
      kind: SignalKindInfo.fromKey(json['kind'] as String? ?? 'gaze'),
      deviation: (json['deviation'] as num? ?? 0).toDouble(),
      detail: json['detail'] as String? ?? '',
    );
  }
}

enum Verdict {
  coherent,
  doubtful,
  inconsistent;

  static Verdict fromScore(double score) {
    if (score >= 72) return Verdict.coherent;
    if (score >= 45) return Verdict.doubtful;
    return Verdict.inconsistent;
  }
}

extension VerdictInfo on Verdict {
  String get label {
    switch (this) {
      case Verdict.coherent:
        return 'Coherente';
      case Verdict.doubtful:
        return 'Dudoso';
      case Verdict.inconsistent:
        return 'Inconsistente';
    }
  }

  String get short {
    switch (this) {
      case Verdict.coherent:
        return 'Coherente';
      case Verdict.doubtful:
        return 'Dudoso';
      case Verdict.inconsistent:
        return 'Inconsistente';
    }
  }

  String get description {
    switch (this) {
      case Verdict.coherent:
        return 'El comportamiento facial se mantuvo cerca de tu línea base.';
      case Verdict.doubtful:
        return 'Aparecieron señales de tensión intermitentes. Conviene repetir.';
      case Verdict.inconsistent:
        return 'Se detectaron desviaciones sostenidas frente a tu línea base.';
    }
  }

  static Verdict fromScore(double score) {
    if (score >= 72) return Verdict.coherent;
    if (score >= 45) return Verdict.doubtful;
    return Verdict.inconsistent;
  }
}
