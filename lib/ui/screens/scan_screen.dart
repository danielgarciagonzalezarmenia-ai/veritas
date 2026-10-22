import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/questions.dart';
import '../../models/signals.dart';
import '../../services/scan_controller.dart';
import '../../services/truth_engine.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/score_ring.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.state, required this.subject});

  final AppState state;
  final String subject;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final ScanController _controller;
  late final AnimationController _scanLine;
  late final List<String> _questions;
  int _questionIndex = 0;
  int _questionsSeen = 1;
  bool _finishing = false;
  bool _paused = false;
  ScanPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _questions = [...kControlQuestions.take(2), ...kTruthQuestions];
    _controller = ScanController(
      sensitivity: widget.state.settings.sensitivity,
      calibrationSeconds: widget.state.settings.calibrationSeconds,
    );
    _controller.addListener(_onTick);
    WidgetsBinding.instance.addObserver(this);
    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _controller.start();
  }

  void _onTick() {
    if (!mounted) return;
    final phase = _controller.engine.snapshot.phase;
    if (_lastPhase != phase) {
      if (_lastPhase == ScanPhase.calibrating && phase == ScanPhase.analyzing) {
        _haptic(HapticFeedback.mediumImpact);
      }
      _lastPhase = phase;
    }
    setState(() {});
  }

  void _haptic(Future<void> Function() action) {
    if (widget.state.settings.haptics) action();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controller.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanLine.dispose();
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    final snapshot = _controller.engine.snapshot;
    if (!snapshot.analysisReady) return;
    if (snapshot.validFrames < 25) {
      _showSnack('Analiza unos segundos más para estabilizar la lectura.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Finalizar análisis?'),
        content: const Text(
          'Generaré el informe con las señales registradas hasta ahora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ver resultado'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _finishing = true);
    final summary = await _controller.finish();
    if (summary == null || !mounted) {
      setState(() => _finishing = false);
      return;
    }

    final session = summary.toSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      startedAt: _controller.startedAt,
      subject: widget.subject,
      notes: '',
      questions: _questionsSeen,
    );
    await widget.state.addSession(session);
    _haptic(HapticFeedback.heavyImpact);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) =>
            ResultScreen(state: widget.state, session: session),
      ),
    );
  }

  Future<void> _cancel() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar análisis'),
        content: const Text('No se guardará esta sesión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (shouldLeave == true && mounted) Navigator.of(context).pop();
  }

  void _nextQuestion([int delta = 1]) {
    _haptic(HapticFeedback.selectionClick);
    setState(() {
      _questionIndex = (_questionIndex + delta) % _questions.length;
      if (_questionsSeen < _questions.length) _questionsSeen++;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.surfaceSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _togglePause() async {
    if (_paused) {
      await _controller.resume();
    } else {
      await _controller.pause();
    }
    if (mounted) setState(() => _paused = !_paused);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final snapshot = _controller.engine.snapshot;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _cameraLayer()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0, 0.25, 0.55, 0.8],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(snapshot),
                Expanded(child: _faceStage(snapshot)),
                _panel(snapshot),
              ],
            ),
          ),
          if (_paused && _controller.cameraReady)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pause_circle_outline_rounded,
                        size: 58,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ANÁLISIS EN PAUSA',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_finishing)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: c.orange),
                      const SizedBox(height: 16),
                      Text(
                        'Generando informe…',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cameraLayer() {
    final controller = _controller.camera;
    if (_controller.cameraReady && controller != null) {
      final preview = controller.value.previewSize;
      if (preview == null) return const ColoredBox(color: Colors.black);
      return ClipRect(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: preview.height,
              height: preview.width,
              child: CameraPreview(controller),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0F09), Color(0xFF060506)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: _controller.error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      child: const Icon(
                        Icons.videocam_off_outlined,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Cámara no disponible',
                      style: context.texts.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _controller.error!,
                      textAlign: TextAlign.center,
                      style: context.texts.bodySmall?.copyWith(
                        color: Colors.white60,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GhostPill(
                      label: 'Reintentar',
                      icon: Icons.refresh_rounded,
                      onTap: _controller.start,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: context.colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Preparando cámara…',
                      style: context.texts.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _header(EngineSnapshot snapshot) {
    final live = snapshot.phase == ScanPhase.analyzing && !_paused;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.close_rounded,
            background: Colors.black.withValues(alpha: 0.35),
            color: Colors.white,
            onTap: _cancel,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (live)
                  const _PulseDot()
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                const SizedBox(width: 7),
                Text(
                  live ? 'EN VIVO' : 'PREPARANDO',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                if (snapshot.phase == ScanPhase.analyzing) ...[
                  const SizedBox(width: 9),
                  Container(
                    width: 1,
                    height: 11,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    _clock(snapshot.elapsedSec),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          RoundIconButton(
            icon: Icons.help_outline_rounded,
            background: Colors.black.withValues(alpha: 0.35),
            color: Colors.white,
            onTap: _showHelp,
          ),
        ],
      ),
    );
  }

  Widget _faceStage(EngineSnapshot snapshot) {
    final calibrating = snapshot.phase == ScanPhase.calibrating;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 252,
              height: 318,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FaceGuidePainter(
                        color: calibrating
                            ? Colors.white.withValues(alpha: 0.55)
                            : context.colors.orange,
                        detected: snapshot.facePresent,
                      ),
                    ),
                  ),
                  if (snapshot.phase == ScanPhase.analyzing && !_paused)
                    AnimatedBuilder(
                      animation: _scanLine,
                      builder: (context, child) => Positioned(
                        left: 20,
                        right: 20,
                        top: 24 + (318 - 48) * _scanLine.value,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                context.colors.orangeSoft,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.orange.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (calibrating)
                    Center(
                      child: ScoreRing(
                        score: snapshot.calibrationProgress * 100,
                        size: 124,
                        stroke: 7,
                        color: Colors.white,
                        background: Colors.white.withValues(alpha: 0.14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(widget.state.settings.calibrationSeconds * (1 - snapshot.calibrationProgress)).ceil()}',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                height: 1,
                                letterSpacing: -1.5,
                                color: Colors.white,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'CALIBRANDO',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -6,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              snapshot.facePresent
                                  ? Icons.face_retouching_natural_rounded
                                  : Icons.face_retouching_off_rounded,
                              size: 13,
                              color: snapshot.facePresent
                                  ? context.colors.green
                                  : Colors.orangeAccent,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                snapshot.hint,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel(EngineSnapshot snapshot) {
    final c = context.colors;
    final calibrating = snapshot.phase == ScanPhase.calibrating;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.56,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: calibrating
                  ? _calibrationPanel(snapshot)
                  : _analysisPanel(snapshot),
            ),
          ),
        ),
      ),
    );
  }

  Widget _calibrationPanel(EngineSnapshot snapshot) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            ScoreRing(
              score: snapshot.calibrationProgress * 100,
              size: 62,
              stroke: 5,
              color: c.orange,
              child: Icon(
                Icons.self_improvement_rounded,
                color: c.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calibrando tu línea base',
                    style: context.texts.titleLarge?.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Rostro neutro, hombros relajados y buena luz frontal.',
                    style: context.texts.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '${snapshot.calibrationProgress * 100 ~/ 1}%',
              style: context.texts.headlineSmall?.copyWith(
                color: c.orange,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: snapshot.calibrationProgress,
            minHeight: 6,
            backgroundColor: c.line,
            valueColor: AlwaysStoppedAnimation<Color>(c.orange),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatusTile(
                icon: Icons.face_rounded,
                label: 'Rostro',
                value: snapshot.facePresent ? 'Detectado' : 'Buscando',
                color: snapshot.facePresent ? c.green : c.amber,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatusTile(
                icon: Icons.bolt_rounded,
                label: 'Frames',
                value: '${snapshot.validFrames}',
                color: c.orangeSoft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatusTile(
                icon: Icons.timer_outlined,
                label: 'Calibración',
                value: '${widget.state.settings.calibrationSeconds}s',
                color: c.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Consejo: no sonrías ni hables durante la calibración. Veritas necesita '
          'tu expresión en reposo para detectar cambios reales.',
          style: context.texts.bodySmall?.copyWith(height: 1.45),
        ),
      ],
    );
  }

  Widget _analysisPanel(EngineSnapshot snapshot) {
    final c = context.colors;
    final score = snapshot.coherence;
    final accent = verdictColor(c, score);
    final verdict = Verdict.fromScore(score);
    final nextQuestion = _questions[_questionIndex];
    final question = snapshot.phase == ScanPhase.finished
        ? 'Análisis completado'
        : nextQuestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.muted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            ScoreRing(
              score: score,
              size: 84,
              stroke: 6,
              color: accent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${score.round()}',
                    style: context.texts.headlineMedium?.copyWith(
                      fontSize: 25,
                      color: accent,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '%',
                    style: context.texts.bodySmall?.copyWith(
                      fontSize: 8,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'COHERENCIA',
                        style: context.texts.labelMedium?.copyWith(
                          fontSize: 9.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TagPill(
                        label: verdict.short,
                        color: accent,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    verdict.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall?.copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 11,
                        color: c.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Confianza ${(snapshot.confidence * 100).round()}%',
                        style: context.texts.bodySmall?.copyWith(fontSize: 10),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.bolt_rounded, size: 11, color: c.muted),
                      const SizedBox(width: 4),
                      Text(
                        '${snapshot.blinkRate.round()} parpadeos/min',
                        style: context.texts.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _LiveSignal(
                  reading: snapshot.signals[i],
                  color: signalColor(c, snapshot.signals[i].deviation),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 3; i < 6; i++) ...[
              if (i > 3) const SizedBox(width: 8),
              Expanded(
                child: _LiveSignal(
                  reading: snapshot.signals[i],
                  color: signalColor(c, snapshot.signals[i].deviation),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: c.surfaceAlt,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.line.withValues(alpha: 0.65)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.orange.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.record_voice_over_rounded,
                  size: 17,
                  color: c.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'PREGUNTA ${_questionIndex + 1}',
                          style: context.texts.labelSmall?.copyWith(
                            fontSize: 8.5,
                            color: c.orange,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· pide detalle',
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                icon: Icons.chevron_left_rounded,
                size: 30,
                iconSize: 16,
                onTap: () => _nextQuestion(-1),
              ),
              const SizedBox(width: 2),
              RoundIconButton(
                icon: Icons.chevron_right_rounded,
                size: 30,
                iconSize: 16,
                onTap: _nextQuestion,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            RoundIconButton(
              icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 50,
              onTap: _togglePause,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryPill(
                label: 'Finalizar y ver informe',
                icon: Icons.insights_rounded,
                onTap: _finishing ? null : _finish,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cómo leer el análisis'),
        content: const Text(
          '1. Calibración: 10 s de rostro neutro para fijar tu línea base.\n'
          '2. Preguntas: habla con naturalidad y sostén la mirada.\n'
          '3. Señales: Veritas compara cada gesto con tu propio reposo. '
          'Verde = cerca de la base, ámbar = tensión, naranja = desviación.\n\n'
          'La puntuación mide coherencia conductual, no prueba una mentira.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  String _clock(double seconds) {
    final total = seconds.round();
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final rest = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.titleMedium?.copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _LiveSignal extends StatelessWidget {
  const _LiveSignal({required this.reading, required this.color});

  final SignalReading reading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(signalIcon(reading.kind), size: 12, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  reading.kind.shortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 9.5,
                    color: c.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: reading.deviation.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: c.line,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reading.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodySmall?.copyWith(fontSize: 8.5),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFFFF453A),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  const _FaceGuidePainter({required this.color, required this.detected});

  final Color color;
  final bool detected;

  @override
  void paint(Canvas canvas, Size size) {
    final corner = 26.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(38),
    );
    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final length = metric.length;
      for (final fraction in [0.0, 0.25, 0.5, 0.75]) {
        final start = length * fraction;
        canvas.drawPath(metric.extractPath(start, start + corner), paint);
      }
    }

    final soft = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rect, soft);

    final ovalPaint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.47),
        width: size.width * 0.56,
        height: size.height * 0.62,
      ),
      ovalPaint,
    );

    if (detected) {
      final dot = Paint()..color = color.withValues(alpha: 0.85);
      canvas.drawCircle(Offset(size.width / 2, 10), 2.2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.detected != detected;
  }
}
