import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veritas/models/session.dart';
import 'package:veritas/models/signals.dart';
import 'package:veritas/services/session_store.dart';
import 'package:veritas/state/app_state.dart';
import 'package:veritas/ui/screens/history_screen.dart';
import 'package:veritas/ui/screens/home_screen.dart';
import 'package:veritas/ui/screens/insights_screen.dart';
import 'package:veritas/ui/screens/result_screen.dart';
import 'package:veritas/ui/screens/settings_screen.dart';
import 'package:veritas/ui/theme.dart';

Session sampleSession({
  required String id,
  required String subject,
  required double score,
  required DateTime startedAt,
}) {
  final verdict = Verdict.fromScore(score);
  return Session(
    id: id,
    startedAt: startedAt,
    durationSec: 148,
    subject: subject,
    score: score,
    verdict: verdict,
    confidence: 0.84,
    peakInconsistency: 0.58,
    blinkRate: 17.4,
    frames: 1140,
    faceCoverage: 0.91,
    questions: 5,
    signals: const [
      SignalReading(
        kind: SignalKind.gaze,
        deviation: 0.18,
        detail: 'Mirada estable',
      ),
      SignalReading(
        kind: SignalKind.lips,
        deviation: 0.42,
        detail: 'Tensión breve',
      ),
      SignalReading(
        kind: SignalKind.head,
        deviation: 0.27,
        detail: 'Microgestos leves',
      ),
      SignalReading(
        kind: SignalKind.blink,
        deviation: 0.31,
        detail: 'Parpadeo regular',
      ),
      SignalReading(
        kind: SignalKind.asymmetry,
        deviation: 0.12,
        detail: 'Rostro simétrico',
      ),
      SignalReading(
        kind: SignalKind.expression,
        deviation: 0.22,
        detail: 'Expresión contenida',
      ),
    ],
    timeline: const [88, 84, 79, 82, 74, 71, 76, 68, 72, 70, 74, 77, 80, 78],
    notes: 'Sesión de prueba',
  );
}

Future<void> loadManrope() async {
  final loader = FontLoader('Manrope');
  for (final weight in [300, 400, 500, 600, 700, 800]) {
    loader.addFont(rootBundle.load('assets/fonts/Manrope-$weight.ttf'));
  }
  await loader.load();
}

AppState seededState() {
  final state = AppState(SessionStore());
  state.ready = true;
  state.sessions = [
    sampleSession(
      id: 'a',
      subject: 'Lucía',
      score: 78,
      startedAt: DateTime(2026, 10, 21, 19, 30),
    ),
    sampleSession(
      id: 'b',
      subject: 'Andrés',
      score: 54,
      startedAt: DateTime(2026, 10, 20, 12, 10),
    ),
    sampleSession(
      id: 'c',
      subject: 'Sujeto anónimo',
      score: 38,
      startedAt: DateTime(2026, 10, 18, 9, 5),
    ),
  ];
  return state;
}

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VeritasTheme.dark(),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadManrope);

  testWidgets('home renderiza con sesiones', (tester) async {
    await pumpScreen(tester, HomeScreen(state: seededState()));
    expect(find.text('Coherencia media'), findsOneWidget);
  });

  testWidgets('historial lista sesiones', (tester) async {
    await pumpScreen(tester, HistoryScreen(state: seededState()));
    expect(find.text('Lucía'), findsOneWidget);
    expect(find.text('Andrés'), findsOneWidget);
  });

  testWidgets('progreso muestra métricas', (tester) async {
    await pumpScreen(tester, InsightsScreen(state: seededState()));
    expect(find.text('Coherencia media'), findsWidgets);
  });

  testWidgets('resultado muestra veredicto', (tester) async {
    final state = seededState();
    await pumpScreen(
      tester,
      ResultScreen(state: state, session: state.sessions.first),
    );
    expect(find.text('COHERENTE'), findsWidgets);
  });

  testWidgets('ajustes renderiza secciones', (tester) async {
    await pumpScreen(tester, SettingsScreen(state: seededState()));
    expect(find.text('Sensibilidad'), findsOneWidget);
    expect(find.text('Calibración'), findsOneWidget);
  });
}
