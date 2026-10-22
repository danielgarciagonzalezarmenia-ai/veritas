import 'package:flutter/material.dart';

import '../../models/session.dart';
import '../../models/signals.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/score_ring.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.state, this.onOpenScan});

  final AppState state;
  final VoidCallback? onOpenScan;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'all';

  List<Session> get _filtered {
    final sessions = widget.state.sessions;
    switch (_filter) {
      case 'coherent':
        return sessions.where((session) => session.score >= 72).toList();
      case 'doubtful':
        return sessions
            .where((session) => session.score >= 45 && session.score < 72)
            .toList();
      case 'inconsistent':
        return sessions.where((session) => session.score < 45).toList();
      default:
        return sessions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sessions = _filtered;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Historial',
                                style: context.texts.headlineLarge?.copyWith(
                                  fontSize: 34,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.state.sessions.length} lecturas guardadas en este iPhone',
                                style: context.texts.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        RoundIconButton(
                          icon: Icons.add_rounded,
                          size: 44,
                          filled: true,
                          onTap: widget.onOpenScan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _SummaryStrip(state: widget.state),
                    const SizedBox(height: 18),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Todas',
                            active: _filter == 'all',
                            onTap: () => setState(() => _filter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Coherentes',
                            active: _filter == 'coherent',
                            color: c.green,
                            onTap: () => setState(() => _filter = 'coherent'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Dudosas',
                            active: _filter == 'doubtful',
                            color: c.amber,
                            onTap: () => setState(() => _filter = 'doubtful'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Inconsistentes',
                            active: _filter == 'inconsistent',
                            color: c.orange,
                            onTap: () =>
                                setState(() => _filter = 'inconsistent'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ]),
                ),
              ),
              if (sessions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyHistory(onTap: widget.onOpenScan),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                  sliver: SliverList.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: ValueKey(session.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDelete(session),
                          onDismissed: (_) =>
                              widget.state.deleteSession(session.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: c.red.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: c.red,
                            ),
                          ),
                          child: _HistoryCard(
                            session: session,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => ResultScreen(
                                    state: widget.state,
                                    session: session,
                                  ),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(Session session) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lectura'),
        content: Text(
          'Se borrará la sesión de ${session.subject} del historial local.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        colors: [c.surfaceAlt, c.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          ScoreRing(
            score: state.averageScore,
            size: 62,
            stroke: 5.5,
            color: verdictColor(c, state.averageScore),
            child: Text(
              state.sessions.isEmpty ? '—' : '${state.averageScore.round()}',
              style: context.texts.titleLarge?.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coherencia media', style: context.texts.titleMedium),
                const SizedBox(height: 3),
                Text(
                  state.sessions.isEmpty
                      ? 'Sin lecturas todavía'
                      : '${state.coherentCount} coherentes · ${state.inconsistentCount} inconsistentes',
                  style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${state.sessions.length}',
                style: context.texts.headlineMedium?.copyWith(
                  fontSize: 24,
                  color: c.text,
                ),
              ),
              Text(
                'SESIONES',
                style: context.texts.labelSmall?.copyWith(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = color ?? c.orange;
    return Pressable(
      onTap: onTap,
      borderRadius: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: 0.16)
              : c.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? accent.withValues(alpha: 0.45) : c.line,
          ),
        ),
        child: Text(
          label,
          style: context.texts.bodySmall?.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? accent : c.muted,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.session, required this.onTap});

  final Session session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = verdictColor(c, session.score);
    final verdict = session.verdict;
    return Pressable(
      onTap: onTap,
      borderRadius: 24,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.line.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            ScoreRing(
              score: session.score,
              size: 56,
              stroke: 5,
              color: accent,
              background: c.line.withValues(alpha: 0.5),
              child: Text(
                '${session.score.round()}',
                style: context.texts.titleLarge?.copyWith(
                  fontSize: 14,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.titleMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        friendlyDateTime(session.startedAt),
                        style: context.texts.bodySmall?.copyWith(
                          fontSize: 10.5,
                        ),
                      ),
                      Text(
                        ' · ${durationLabel(session.durationSec)}',
                        style: context.texts.bodySmall?.copyWith(
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      TagPill(
                        label: verdict.short,
                        color: accent,
                        compact: true,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${(session.confidence * 100).round()}% confianza',
                        style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: c.muted.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 130),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.orange.withValues(alpha: 0.08),
              border: Border.all(color: c.orange.withValues(alpha: 0.18)),
            ),
            child: Icon(Icons.history_rounded, size: 32, color: c.orange),
          ),
          const SizedBox(height: 20),
          Text('Todavía no hay lecturas', style: context.texts.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Cada análisis se guarda aquí, en tu iPhone. Nada viaja a la nube.',
            textAlign: TextAlign.center,
            style: context.texts.bodySmall?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 24),
          GhostPill(
            label: 'Crear primer análisis',
            icon: Icons.add_rounded,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
