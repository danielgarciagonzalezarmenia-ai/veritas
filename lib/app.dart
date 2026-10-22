import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/app_state.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/root_shell.dart';
import 'ui/theme.dart';

class VeritasApp extends StatelessWidget {
  const VeritasApp({super.key, required this.state});

  final AppState state;

  ThemeMode get _mode {
    switch (state.settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return MaterialApp(
          title: 'Veritas',
          debugShowCheckedModeBanner: false,
          theme: VeritasTheme.light(),
          darkTheme: VeritasTheme.dark(),
          themeMode: _mode,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: state.ready && state.settings.onboarded
              ? RootShell(state: state)
              : OnboardingScreen(state: state),
        );
      },
    );
  }
}
