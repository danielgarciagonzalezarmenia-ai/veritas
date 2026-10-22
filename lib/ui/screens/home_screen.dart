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
import 'result_screen.dart';
import '../widgets/scan_setup_sheet.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.state,
    this.onOpenSettings,
    this.onOpenHistory,
  });

  final AppState state;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenHistory;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    final subject = await showScanSetup(context, widget.state);
    if (subject == null || !mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ScanScreen(state: widget.state, subject: subject),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = widget.state;
    final sessions = state.sessions;
    final score = state.averageScore;
    final last = state.lastSession;
    final recent = sessions.take(3).toList();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const VeritasMark(size: 48),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Wordmark(fontSize: 14),
                        const SizedBox(height: 2),
                        Text(
                          'Análisis conductual',
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 10.5,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    TagPill(label: 'LOCAL', color: c.green, compact: true),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: Icons.tune_rounded,
                      onTap: widget.onOpenSettings,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    sessions.isEmpty
                        ? 'Sin análisis todavía'
                        : 'Coherencia media',
                    style: context.texts.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          sessions.isEmpty ? '—' : '${score.round()}',
                          style: context.texts.displayLarge?.copyWith(
                            fontSize: sessions.isEmpty ? 58 : 72,
                          ),
                        ),
                        if (sessions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              '%',
                              style: context.texts.displaySmall?.copyWith(
                                color: c.muted,
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      sessions.isEmpty
                          ? 'Calibra tu línea base'
                          : '${sessions.length} ${sessions.length == 1 ? 'sesión' : 'sesiones'}',
                      style: context.texts.bodySmall?.copyWith(
                        color: c.muted,
                        fontSize: 12,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '·',
                        style: TextStyle(color: c.muted.withValues(alpha: 0.6)),
                      ),
                    ),
                    Text(
                      '6 señales',
                      style: context.texts.bodySmall?.copyWith(
                        color: c.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 288,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _page = index);
                    },
                    children: [
                      _HeroScanCard(
                        onScan: _startAnalysis,
                        onSensitivity: widget.onOpenSettings,
                        avgScore: score,
                        hasData: sessions.isNotEmpty,
                      ),
                      _HeroSignalsCard(onTap: () => _showMethodology(context)),
                      _HeroPrivacyCard(
                        onTap: widget.onOpenSettings,
                        sessions: sessions.length,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _page == i ? 7 : 5,
                        height: _page == i ? 7 : 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _page == i
                              ? c.text
                              : c.muted.withValues(alpha: 0.35),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Sesiones recientes',
                  actionLabel: 'Ver todo',
                  onAction: () => _openHistory(context),
                ),
                const SizedBox(height: 14),
                if (recent.isEmpty)
                  _EmptyRecent(onTap: _startAnalysis)
                else
                  ...recent.map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SessionRow(
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
                  ),
                const SizedBox(height: 16),
                _TodayCard(
                  state: state,
                  lastScore: last?.score,
                  onTap: _startAnalysis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openHistory(BuildContext context) {
    widget.onOpenHistory?.call();
  }

  void _showMethodology(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cómo analiza Veritas'),
        content: const Text(
          'Veritas compara tu comportamiento facial con una línea base '
          'personal capturada antes de empezar.\n\n'
          'Señales: tensión labial, parpadeo, mirada, microgestos de cabeza, '
          'asimetría facial y fluctuaciones de expresión.\n\n'
          'Es una herramienta de observación conductual, no un polígrafo: no '
          'existe una relación científica unívoca entre estos gestos y la mentira.',
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
}

class _HeroScanCard extends StatelessWidget {
  const _HeroScanCard({
    required this.onScan,
    required this.onSensitivity,
    required this.avgScore,
    required this.hasData,
  });

  final VoidCallback onScan;
  final VoidCallback? onSensitivity;
  final double avgScore;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.heroTop, c.heroMid, c.heroBottom],
          stops: const [0, 0.52, 1],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: c.orange.withValues(alpha: 0.16),
            blurRadius: 42,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _HeroGlowPainter(
                  color: c.orangeSoft.withValues(alpha: 0.28),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Pressable(
                        onTap: onScan,
                        scale: 0.9,
                        borderRadius: 30,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: c.orange,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _Orb(
                        icon: Icons.remove_red_eye_outlined,
                        color: c.orange,
                        label: 'MI',
                      ),
                      _Orb(
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        color: const Color(0xFFB9A7FF),
                        label: 'LA',
                      ),
                      _Orb(
                        icon: Icons.graphic_eq_rounded,
                        color: const Color(0xFF6FD3C7),
                        label: 'PA',
                      ),
                      _Orb(
                        icon: Icons.more_horiz_rounded,
                        color: c.muted,
                        label: '+3',
                        muted: true,
                      ),
                      const Spacer(),
                      RoundIconButton(
                        icon: Icons.tune_rounded,
                        size: 42,
                        background: Colors.black.withValues(alpha: 0.22),
                        onTap: onSensitivity,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    hasData ? 'Línea base activa' : 'Tu primera lectura',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasData
                        ? 'Coherencia ${avgScore.round()}% en tus últimas sesiones'
                        : 'Analiza microexpresiones en tiempo real',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _HeroChip(
                        icon: Icons.lock_outline_rounded,
                        label: 'En el dispositivo',
                      ),
                      const SizedBox(width: 8),
                      _HeroChip(icon: Icons.bolt_rounded, label: '6 señales'),
                    ],
                  ),
                  const Spacer(),
                  Pressable(
                    onTap: onScan,
                    borderRadius: 30,
                    child: Container(
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 6),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [c.orangeSoft, c.orange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.center_focus_strong_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Nuevo análisis',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: c.bg,
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: c.bg.withValues(alpha: 0.5),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSignalsCard extends StatelessWidget {
  const _HeroSignalsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surfaceAlt, c.surface, c.heroMid],
        ),
        border: Border.all(color: c.line.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [c.orangeSoft, c.orange]),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Señales en vivo',
                style: context.texts.headlineSmall?.copyWith(fontSize: 19),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in SignalKind.values)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceSoft.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.line.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(signalIcon(kind), size: 14, color: c.orangeSoft),
                      const SizedBox(width: 6),
                      Text(
                        kind.shortLabel,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: c.text,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Pressable(
            onTap: onTap,
            borderRadius: 30,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.orange,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ver metodología',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.bg,
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: c.bg.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPrivacyCard extends StatelessWidget {
  const _HeroPrivacyCard({required this.sessions, this.onTap});

  final int sessions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surfaceAlt, c.surface],
        ),
        border: Border.all(color: c.line.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.green.withValues(alpha: 0.14),
                  border: Border.all(color: c.green.withValues(alpha: 0.25)),
                ),
                child: Icon(Icons.shield_outlined, color: c.green, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '100% en tu iPhone',
                  style: context.texts.headlineSmall?.copyWith(fontSize: 19),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'La cámara analiza en el dispositivo. No hay cuentas, servidores ni '
            'telemetría: tus sesiones se guardan en un archivo local.',
            style: context.texts.bodyMedium?.copyWith(
              color: c.muted,
              height: 1.45,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _PrivacyStat(value: '$sessions', label: 'sesiones guardadas'),
              const SizedBox(width: 22),
              _PrivacyStat(value: '0', label: 'datos enviados'),
              const Spacer(),
              RoundIconButton(
                icon: Icons.arrow_outward_rounded,
                size: 40,
                onTap: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivacyStat extends StatelessWidget {
  const _PrivacyStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: context.texts.titleLarge?.copyWith(fontSize: 20)),
        Text(
          label,
          style: context.texts.bodySmall?.copyWith(
            fontSize: 10.5,
            color: c.muted,
          ),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.icon,
    required this.color,
    required this.label,
    this.muted = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: muted
              ? Colors.black.withValues(alpha: 0.28)
              : color.withValues(alpha: 0.18),
          border: Border.all(
            color: muted
                ? Colors.white.withValues(alpha: 0.14)
                : color.withValues(alpha: 0.45),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 18, color: muted ? Colors.white70 : color),
            Positioned(
              bottom: 3,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 6,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: muted
                      ? Colors.white70
                      : Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroGlowPainter extends CustomPainter {
  const _HeroGlowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
          .createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.78, size.height * 0.25),
              radius: size.width * 0.55,
            ),
          );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _HeroGlowPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onTap});

  final Session session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final score = session.score;
    final accent = verdictColor(c, score);
    final verdict = Verdict.fromScore(score);
    return Pressable(
      onTap: onTap,
      borderRadius: 24,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.16),
              accent.withValues(alpha: 0.04),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.18),
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Icon(
                verdict == Verdict.coherent
                    ? Icons.verified_rounded
                    : Icons.graphic_eq_rounded,
                color: accent,
                size: 22,
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
                    style: context.texts.titleMedium?.copyWith(fontSize: 14.5),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        friendlyDateTime(session.startedAt),
                        style: context.texts.bodySmall?.copyWith(
                          fontSize: 10.5,
                        ),
                      ),
                      Text(
                        ' • ${durationLabel(session.durationSec)}',
                        style: context.texts.bodySmall?.copyWith(
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${score.round()}%',
                  style: context.texts.titleLarge?.copyWith(
                    fontSize: 19,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      verdict == Verdict.coherent
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 11,
                      color: accent,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      verdict.short,
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 10,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.orange.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.timeline_rounded, color: c.orange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aún no hay lecturas', style: context.texts.titleMedium),
                const SizedBox(height: 3),
                Text(
                  'Tu primera sesión creará la línea base.',
                  style: context.texts.bodySmall,
                ),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.arrow_forward_rounded,
            size: 38,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.state,
    required this.lastScore,
    required this.onTap,
  });

  final AppState state;
  final double? lastScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SurfaceCard(
      gradient: LinearGradient(
        colors: [c.surfaceAlt, c.surface.withValues(alpha: 0.6)],
      ),
      child: Row(
        children: [
          ScoreRing(
            score: lastScore ?? 0,
            size: 64,
            stroke: 6,
            color: lastScore == null ? c.muted : verdictColor(c, lastScore!),
            child: Text(
              lastScore == null ? '—' : '${lastScore!.round()}',
              style: context.texts.titleLarge?.copyWith(fontSize: 17),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lastScore == null ? 'Tu primera lectura' : 'Último análisis',
                  style: context.texts.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  state.lastSession == null
                      ? 'Todo listo para empezar.'
                      : '${friendlyDateTime(state.lastSession!.startedAt)} · ${durationLabel(state.lastSession!.durationSec)}',
                  style: context.texts.bodySmall,
                ),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.play_arrow_rounded,
            size: 42,
            filled: true,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
