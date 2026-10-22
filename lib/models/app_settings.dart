class AppSettings {
  const AppSettings({
    this.sensitivity = 1.0,
    this.calibrationSeconds = 10,
    this.haptics = true,
    this.themeMode = 'dark',
    this.onboarded = false,
  });

  final double sensitivity;
  final int calibrationSeconds;
  final bool haptics;
  final String themeMode;
  final bool onboarded;

  AppSettings copyWith({
    double? sensitivity,
    int? calibrationSeconds,
    bool? haptics,
    String? themeMode,
    bool? onboarded,
  }) {
    return AppSettings(
      sensitivity: sensitivity ?? this.sensitivity,
      calibrationSeconds: calibrationSeconds ?? this.calibrationSeconds,
      haptics: haptics ?? this.haptics,
      themeMode: themeMode ?? this.themeMode,
      onboarded: onboarded ?? this.onboarded,
    );
  }

  Map<String, dynamic> toJson() => {
    'sensitivity': sensitivity,
    'calibrationSeconds': calibrationSeconds,
    'haptics': haptics,
    'themeMode': themeMode,
    'onboarded': onboarded,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      sensitivity: ((json['sensitivity'] as num? ?? 1.0).toDouble()).clamp(
        0.6,
        1.6,
      ),
      calibrationSeconds: (json['calibrationSeconds'] as num? ?? 10)
          .toInt()
          .clamp(5, 30),
      haptics: json['haptics'] as bool? ?? true,
      themeMode: json['themeMode'] as String? ?? 'dark',
      onboarded: json['onboarded'] as bool? ?? false,
    );
  }
}
