import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/session.dart';
import '../../models/signals.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/score_ring.dart';
import '../widgets/veritas_mark.dart';
import 'scan_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.state, required this.session});

  final AppState state;
  final Session session;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Session _session = widget.session;
  late final TextEditingController _notes = TextEditingController(
    text: widget.session.notes,
  );
  bool _notesDirty = false;
  bool _saved = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    final updated = _session.copyWith(notes: _notes.text.trim());
    setState(() {
      _session = updated;
      _notesDirty = false;
      _saved = true;
    });
    await widget.state.addSession(updated);
    if (widget.state.settings.haptics) {
      HapticFeedback.lightImpact();
    }
    if (!mounted) return;
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Future<void> _rename(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final updated = _session.copyWith(subject: trimmed);
    setState(() => _session = updated);
    await widget.state.addSession(updated);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar análisis'),
        content: const Text('Esta lectura se borrará del historial local.'),
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
    if (confirmed != true) return;
    await widget.state.deleteSession(_session.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _repeat() async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) =>
            ScanScreen(state: widget.state, subject: _session.subject),
      ),
    );
  }

  void _editName() {
    final controller = TextEditingController(text: _session.subject);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre del sujeto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nombre o alias'),
          onSubmitted: (value) {
            Navigator.of(context).pop();
            _rename(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rename(controller.text);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = verdictColor(c, _session.score);
    final verdict = _session.verdict;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    TagPill(label: 'INFORME', color: c.orange, compact: true),
                    const Spacer(),
                    RoundIconButton(
                      icon: Icons.delete_outline_rounded,
                      onTap: _delete,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  'RESULTADO DEL ANÁLISIS',
                  textAlign: TextAlign.center,
                  style: context.texts.labelMedium?.copyWith(
                    fontSize: 9.5,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [c.orangeSoft, c.orange],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _session.subject.isEmpty
                              ? '?'
                              : _session.subject.characters.first.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _session.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.headlineMedium?.copyWith(
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Pressable(
                      onTap: _editName,
                      borderRadius: 20,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: c.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  friendlyDateTime(_session.startedAt),
                  textAlign: TextAlign.center,
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        c.heroTop,
                        c.heroMid,
                        Color.lerp(c.heroBottom, c.heroMid, 0.35)!,
                      ],
                      stops: const [0, 0.55, 1],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ScoreRing(
                        score: _session.score,
                        size: 196,
                        stroke: 12,
                        color: accent,
                        background: Colors.white.withValues(alpha: 0.10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_session.score.round()}',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 62,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -3,
                                height: 1,
                                color: Colors.white,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              '% COHERENCIA',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              verdict.label.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        verdict.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _HeroStat(
                              label: 'Confianza',
                              value: '${(_session.confidence * 100).round()}%',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          Expanded(
                            child: _HeroStat(
                              label: 'Duración',
                              value: durationLabel(_session.durationSec),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          Expanded(
                            child: _HeroStat(
                              label: 'Muestras',
                              value: '${_session.frames}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SectionHeader(title: 'Desglose de señales'),
                const SizedBox(height: 12),
                SurfaceCard(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: [
                      for (final signal in _session.signals) ...[
                        _SignalResultRow(signal: signal),
                        if (signal != _session.signals.last)
                          Divider(
                            height: 1,
                            color: c.line.withValues(alpha: 0.55),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SectionHeader(title: 'Evolución de la coherencia'),
                const SizedBox(height: 12),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          TagPill(
                            label: 'INICIO',
                            color: c.muted,
                            compact: true,
                          ),
                          const Spacer(),
                          Text(
                            'Pico de tensión ${_session.peakInconsistency.round()}%',
                            style: context.texts.bodySmall?.copyWith(
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Sparkline(values: _session.timeline, height: 112),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Línea base 100%',
                            style: context.texts.bodySmall?.copyWith(
                              fontSize: 9.5,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Container(width: 14, height: 2, color: c.orange),
                              const SizedBox(width: 5),
                              Text(
                                'Coherencia',
                                style: context.texts.bodySmall?.copyWith(
                                  fontSize: 9.5,
                                  color: c.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SectionHeader(
                  title: 'Notas de la sesión',
                  actionLabel: _saved ? 'Guardado' : 'Guardar',
                  onAction: _notesDirty ? _saveNotes : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  minLines: 4,
                  maxLines: 8,
                  onChanged: (_) {
                    if (!_notesDirty) setState(() => _notesDirty = true);
                  },
                  style: context.texts.bodyMedium,
                  decoration: const InputDecoration(
                    hintText:
                        'Contexto, preguntas clave o detalles que quieras recordar…',
                  ),
                ),
                const SizedBox(height: 24),
                SurfaceCard(
                  color: c.surfaceAlt,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: c.amber,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Veritas mide coherencia conductual frente a una línea '
                          'base personal. No determina mentiras ni sustituye una '
                          'entrevista profesional.',
                          style: context.texts.bodySmall?.copyWith(
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                PrimaryPill(
                  label: 'Repetir análisis',
                  icon: Icons.refresh_rounded,
                  onTap: _repeat,
                ),
                const SizedBox(height: 10),
                GhostPill(
                  label: 'Volver al inicio',
                  icon: Icons.home_outlined,
                  expand: true,
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      VeritasMark(size: 18, glow: false),
                      const SizedBox(width: 8),
                      Text(
                        'Análisis local · Veritas 1.0',
                        style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _SignalResultRow extends StatelessWidget {
  const _SignalResultRow({required this.signal});

  final SignalReading signal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = signalColor(c, signal.deviation);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.13),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(signalIcon(signal.kind), size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        signal.kind.label,
                        style: context.texts.titleMedium?.copyWith(
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Text(
                      signal.detail,
                      style: context.texts.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: signal.deviation.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: c.line.withValues(alpha: 0.7),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  signal.kind.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
