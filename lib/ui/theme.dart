import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

@immutable
class VeritasColors extends ThemeExtension<VeritasColors> {
  const VeritasColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceSoft,
    required this.line,
    required this.text,
    required this.muted,
    required this.orange,
    required this.orangeSoft,
    required this.ember,
    required this.green,
    required this.amber,
    required this.red,
    required this.onOrange,
    required this.heroTop,
    required this.heroMid,
    required this.heroBottom,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceSoft;
  final Color line;
  final Color text;
  final Color muted;
  final Color orange;
  final Color orangeSoft;
  final Color ember;
  final Color green;
  final Color amber;
  final Color red;
  final Color onOrange;
  final Color heroTop;
  final Color heroMid;
  final Color heroBottom;

  static const dark = VeritasColors(
    bg: Color(0xFF070609),
    surface: Color(0xFF121014),
    surfaceAlt: Color(0xFF19161B),
    surfaceSoft: Color(0xFF221E24),
    line: Color(0xFF2B262D),
    text: Color(0xFFF8F5F2),
    muted: Color(0xFF9C959E),
    orange: Color(0xFFFF5A00),
    orangeSoft: Color(0xFFFF8A3D),
    ember: Color(0xFF8A2A00),
    green: Color(0xFF37D67A),
    amber: Color(0xFFFFB020),
    red: Color(0xFFFF453A),
    onOrange: Color(0xFFFFFFFF),
    heroTop: Color(0xFF17100C),
    heroMid: Color(0xFF32150A),
    heroBottom: Color(0xFFFF5A00),
  );

  static const light = VeritasColors(
    bg: Color(0xFFF3EEE8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFBF6F0),
    surfaceSoft: Color(0xFFEDE5DC),
    line: Color(0xFFE2D8CE),
    text: Color(0xFF1A1310),
    muted: Color(0xFF7D7269),
    orange: Color(0xFFF55200),
    orangeSoft: Color(0xFFFF8A3D),
    ember: Color(0xFFB23A00),
    green: Color(0xFF159E56),
    amber: Color(0xFFD98A00),
    red: Color(0xFFD9342B),
    onOrange: Color(0xFFFFFFFF),
    heroTop: Color(0xFF24130B),
    heroMid: Color(0xFF5A2007),
    heroBottom: Color(0xFFFF5A00),
  );

  @override
  VeritasColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceSoft,
    Color? line,
    Color? text,
    Color? muted,
    Color? orange,
    Color? orangeSoft,
    Color? ember,
    Color? green,
    Color? amber,
    Color? red,
    Color? onOrange,
    Color? heroTop,
    Color? heroMid,
    Color? heroBottom,
  }) {
    return VeritasColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      line: line ?? this.line,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      orange: orange ?? this.orange,
      orangeSoft: orangeSoft ?? this.orangeSoft,
      ember: ember ?? this.ember,
      green: green ?? this.green,
      amber: amber ?? this.amber,
      red: red ?? this.red,
      onOrange: onOrange ?? this.onOrange,
      heroTop: heroTop ?? this.heroTop,
      heroMid: heroMid ?? this.heroMid,
      heroBottom: heroBottom ?? this.heroBottom,
    );
  }

  @override
  VeritasColors lerp(ThemeExtension<VeritasColors>? other, double t) {
    if (other is! VeritasColors) return this;
    return VeritasColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      line: Color.lerp(line, other.line, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      orangeSoft: Color.lerp(orangeSoft, other.orangeSoft, t)!,
      ember: Color.lerp(ember, other.ember, t)!,
      green: Color.lerp(green, other.green, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      red: Color.lerp(red, other.red, t)!,
      onOrange: Color.lerp(onOrange, other.onOrange, t)!,
      heroTop: Color.lerp(heroTop, other.heroTop, t)!,
      heroMid: Color.lerp(heroMid, other.heroMid, t)!,
      heroBottom: Color.lerp(heroBottom, other.heroBottom, t)!,
    );
  }
}

extension VeritasColorsContext on BuildContext {
  VeritasColors get colors =>
      Theme.of(this).extension<VeritasColors>() ?? VeritasColors.dark;

  TextTheme get texts => Theme.of(this).textTheme;
}

class VeritasTheme {
  static ThemeData dark() => _build(VeritasColors.dark, Brightness.dark);
  static ThemeData light() => _build(VeritasColors.light, Brightness.light);

  static ThemeData _build(VeritasColors c, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Manrope',
      scaffoldBackgroundColor: c.bg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );

    final textTheme = base.textTheme
        .apply(bodyColor: c.text, displayColor: c.text, fontFamily: 'Manrope')
        .copyWith(
          displayLarge: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 68,
            fontWeight: FontWeight.w800,
            letterSpacing: -3,
            height: 0.95,
            color: c.text,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          displayMedium: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 48,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
            height: 1,
            color: c.text,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          displaySmall: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            height: 1.05,
            color: c.text,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.1,
            color: c.text,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: c.text,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: c.text,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: c.text,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: c.text,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: c.text,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: c.text,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            height: 1.35,
            color: c.muted,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: c.text,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: c.muted,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: c.muted,
          ),
        );

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.orange,
      onPrimary: c.onOrange,
      secondary: c.orangeSoft,
      onSecondary: c.onOrange,
      error: c.red,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.text,
      surfaceContainerHighest: c.surfaceSoft,
      outline: c.line,
    );

    return base.copyWith(
      colorScheme: scheme,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[c],
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.line,
      iconTheme: IconThemeData(color: c.text, size: 22),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceAlt,
        modalBackgroundColor: c.surfaceAlt,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: c.orange,
        barBackgroundColor: Colors.transparent,
        textTheme: CupertinoTextThemeData(
          textStyle: textTheme.bodyMedium,
          navLargeTitleTextStyle: textTheme.headlineLarge,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceSoft,
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.orange,
        inactiveTrackColor: c.line,
        thumbColor: c.orange,
        overlayColor: c.orange.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : c.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.orange : c.surfaceSoft,
        ),
      ),
    );
  }
}

Color verdictColor(VeritasColors c, double score) {
  if (score >= 72) return c.green;
  if (score >= 45) return c.amber;
  return c.orange;
}

Color signalColor(VeritasColors c, double deviation) {
  if (deviation < 0.33) return c.green;
  if (deviation < 0.66) return c.amber;
  return c.orange;
}
