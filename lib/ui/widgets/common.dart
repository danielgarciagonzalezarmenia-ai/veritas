import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/signals.dart';
import '../theme.dart';

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.borderRadius = 28,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final double borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down == value || widget.onTap == null) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class PrimaryPill extends StatelessWidget {
  const PrimaryPill({
    super.key,
    required this.label,
    this.onTap,
    this.icon = Icons.arrow_forward_rounded,
    this.trailing,
    this.height = 60,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  final Widget? trailing;
  final double height;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? c.bg : Colors.white;
    final bg = isDark ? c.text : c.orange;

    final content = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: c.orange.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            width: height - 18,
            height: height - 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isDark
                  ? LinearGradient(
                      colors: [c.orangeSoft, c.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isDark ? null : Colors.white,
            ),
            child: loading
                ? Padding(
                    padding: EdgeInsets.all(height * 0.22),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.white : c.orange,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: height * 0.36,
                    color: isDark ? Colors.white : c.orange,
                  ),
          ),
          SizedBox(width: expand ? 16 : 14),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: foreground,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          if (expand) const Spacer(),
          if (expand)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: foreground.withValues(alpha: 0.45),
                size: 22,
              ),
            ),
        ],
      ),
    );

    return Pressable(
      onTap: loading ? null : onTap,
      borderRadius: height / 2,
      child: content,
    );
  }
}

class GhostPill extends StatelessWidget {
  const GhostPill({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.height = 54,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      borderRadius: height / 2,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: c.line),
          color: c.surface.withValues(alpha: 0.6),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: c.text),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: context.texts.titleMedium?.copyWith(
                color: c.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 46,
    this.filled = false,
    this.iconSize = 19,
    this.color,
    this.background,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool filled;
  final double iconSize;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = color ?? c.text;
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      borderRadius: size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              background ??
              (filled ? c.text : c.surface.withValues(alpha: 0.72)),
          border: filled
              ? null
              : Border.all(color: c.line.withValues(alpha: 0.8)),
        ),
        child: Icon(icon, size: iconSize, color: filled ? c.bg : fg),
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.color,
    this.border = true,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final bool border;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border
            ? Border.all(color: c.line.withValues(alpha: 0.7))
            : null,
      ),
      child: child,
    );
  }
}

class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = color ?? c.muted;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 11 : 13, color: accent),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: compact ? 10.5 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.texts.titleLarge?.copyWith(fontSize: 17.5),
            ),
          ),
          if (actionLabel != null)
            Pressable(
              onTap: onAction,
              borderRadius: 20,
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: context.texts.bodySmall?.copyWith(
                      color: c.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.line),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: c.text,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

IconData signalIcon(SignalKind kind) {
  switch (kind) {
    case SignalKind.lips:
      return Icons.sentiment_satisfied_alt_rounded;
    case SignalKind.blink:
      return Icons.visibility_outlined;
    case SignalKind.gaze:
      return Icons.remove_red_eye_outlined;
    case SignalKind.head:
      return Icons.screen_rotation_alt_rounded;
    case SignalKind.asymmetry:
      return Icons.compare_arrows_rounded;
    case SignalKind.expression:
      return Icons.auto_awesome_rounded;
  }
}

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.height = 96,
    this.color,
    this.showGrid = true,
  });

  final List<double> values;
  final double height;
  final Color? color;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: color ?? c.orange,
          grid: c.line.withValues(alpha: 0.5),
          showGrid: showGrid,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.grid,
    required this.showGrid,
  });

  final List<double> values;
  final Color color;
  final Color grid;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      final gridPaint = Paint()
        ..color = grid
        ..strokeWidth = 1;
      for (var i = 1; i < 4; i++) {
        final y = size.height * i / 4;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }
    if (values.isEmpty) return;

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final normalized = (values[i] / 100).clamp(0.0, 1.0);
      final y =
          size.height - normalized * size.height * 0.86 - size.height * 0.07;
      points.add(Offset(x, y));
    }

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final midX = (previous.dx + current.dx) / 2;
      line.quadraticBezierTo(
        previous.dx,
        previous.dy,
        midX,
        (previous.dy + current.dy) / 2,
      );
      line.lineTo(current.dx, current.dy);
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0.55), color],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final last = points.last;
    canvas.drawCircle(
      last,
      5,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(last, 3.2, Paint()..color = color);
    canvas.drawCircle(last, 1.3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.glow = true});

  final Widget child;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: c.bg)),
        if (glow) ...[
          Positioned(
            top: -190,
            right: -130,
            child: IgnorePointer(
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      c.orange.withValues(alpha: 0.20),
                      c.orange.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 220,
            left: -200,
            child: IgnorePointer(
              child: Container(
                width: 460,
                height: 460,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      c.ember.withValues(alpha: 0.13),
                      c.ember.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        Positioned.fill(child: child),
      ],
    );
  }
}

class DeltaLabel extends StatelessWidget {
  const DeltaLabel({
    super.key,
    required this.value,
    this.suffix = '',
    this.color,
    this.icon,
  });

  final String value;
  final String suffix;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.colors.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 4),
        ],
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        if (suffix.isNotEmpty)
          Text(
            suffix,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: accent.withValues(alpha: 0.8),
            ),
          ),
      ],
    );
  }
}

double clamp01(double value) => math.min(1, math.max(0, value));
