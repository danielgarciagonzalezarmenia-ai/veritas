import 'package:flutter/material.dart';

import '../../models/signals.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/score_ring.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final sessions = state.sessions;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Progreso',
                  style: context.texts.headlineLarge?.copyWith(fontSize: 34),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patrones agregados de tus lecturas locales.',
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 22),
                _MainCard(state: state),
                const SizedBox(height: 18),
                if (sessions.isEmpty)
                  const _EmptyInsights()
                else ...[
                  _SessionsChart(sessions: sessions),
                  const SizedBox(height: 18),
                  _SignalCard(state: state),
                  const SizedBox(height: 18),
                  _TipCard(state: state),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainCard extends StatelessWidget {
  const _MainCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sessions = state.sessions;
    final score = state.averageScore;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.heroTop, c.heroMid, c.surface],
          stops: const [0, 0.6, 1],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ScoreRing(
                score: score,
                size: 108,
                stroke: 9,
                color: sessions.isEmpty ? c.muted : verdictColor(c, score),
                background: Colors.white.withValues(alpha: 0.1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sessions.isEmpty ? '—' : '${score.round()}',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -1.5,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      '% MEDIA',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coherencia media',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sessions.isEmpty
                          ? 'Realiza tu primer análisis para empezar a ver patrones.'
                          : '${state.coherentCount} de ${sessions.length} lecturas se mantuvieron coherentes.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TagPill(label: 'TODO LOCAL', color: c.green, compact: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _Metric(value: '${sessions.length}', label: 'Sesiones'),
              _Divider(),
              _Metric(
                value: '${(state.averageConfidence * 100).round()}%',
                label: 'Confianza',
              ),
              _Divider(),
              _Metric(
                value: state.averageBlinkRate == 0
                    ? '—'
                    : '${state.averageBlinkRate.round()}',
                label: 'Parpadeos/min',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

class _SessionsChart extends StatelessWidget {
  const _SessionsChart({required this.sessions});

  final List sessions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final recent = sessions.take(8).toList().reversed.toList();
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Últimas sesiones',
                style: context.texts.titleLarge?.copyWith(fontSize: 17),
              ),
              const Spacer(),
              Text(
                'coherencia',
                style: context.texts.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final session in recent)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${(session.score as double).round()}',
                            style: context.texts.bodySmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: verdictColor(c, session.score as double),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height:
                                96 *
                                ((session.score as double) / 100).clamp(
                                  0.12,
                                  1.0,
                                ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  verdictColor(
                                    c,
                                    session.score as double,
                                  ).withValues(alpha: 0.35),
                                  verdictColor(c, session.score as double),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _dayLabel(session.startedAt as DateTime),
                            style: context.texts.bodySmall?.copyWith(
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime date) {
    final day = friendlyDay(date);
    if (day == 'Hoy') return 'HOY';
    if (day == 'Ayer') return 'AYER';
    final parts = day.split(' ');
    return parts.length > 1 ? parts[0].toUpperCase() : day.toUpperCase();
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final averages = <SignalKind, double>{
      for (final kind in SignalKind.values) kind: 0,
    };
    for (final session in state.sessions) {
      for (final signal in session.signals) {
        averages[signal.kind] = averages[signal.kind]! + signal.deviation;
      }
    }
    for (final kind in SignalKind.values) {
      averages[kind] = averages[kind]! / state.sessions.length;
    }
    final ranked = SignalKind.values.toList()
      ..sort((a, b) => averages[a]!.compareTo(averages[b]!));

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Perfil de señales',
            style: context.texts.titleLarge?.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            'Desviación media respecto a tu línea base.',
            style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 16),
          for (final kind in ranked) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: signalColor(
                        c,
                        averages[kind]!,
                      ).withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      signalIcon(kind),
                      size: 15,
                      color: signalColor(c, averages[kind]!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                kind.label,
                                style: context.texts.bodyMedium?.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${(averages[kind]! * 100).round()}%',
                              style: context.texts.bodySmall?.copyWith(
                                fontSize: 10,
                                color: signalColor(c, averages[kind]!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: averages[kind]!.clamp(0.0, 1.0),
                            minHeight: 3,
                            backgroundColor: c.line,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              signalColor(c, averages[kind]!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final averages = <SignalKind, double>{
      for (final kind in SignalKind.values) kind: 0,
    };
    for (final session in state.sessions) {
      for (final signal in session.signals) {
        averages[signal.kind] = averages[signal.kind]! + signal.deviation;
      }
    }
    for (final kind in SignalKind.values) {
      averages[kind] = averages[kind]! / state.sessions.length;
    }
    final ranked = SignalKind.values.toList()
      ..sort((a, b) => averages[a]!.compareTo(averages[b]!));
    final stable = ranked.first;
    final reactive = ranked.last;

    return SurfaceCard(
      color: c.surfaceAlt,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [c.orangeSoft, c.orange]),
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 19,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lectura del perfil', style: context.texts.titleMedium),
                const SizedBox(height: 5),
                Text(
                  'Tu señal más estable es ${stable.label.toLowerCase()}; la más '
                  'reactiva, ${reactive.label.toLowerCase()}. Repite sesiones con '
                  'preguntas de control para afinar la línea base.',
                  style: context.texts.bodySmall?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 34, color: c.muted),
          const SizedBox(height: 12),
          Text('Sin datos agregados', style: context.texts.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Cuando completes al menos una sesión verás aquí tendencias, '
            'perfil de señales y evolución.',
            textAlign: TextAlign.center,
            style: context.texts.bodySmall?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
