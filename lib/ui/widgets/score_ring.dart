import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 132,
    this.stroke = 10,
    this.child,
    this.color,
    this.background,
  });

  final double score;
  final double size;
  final double stroke;
  final Widget? child;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ringColor = color ?? c.orange;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: (score / 100).clamp(0.0, 1.0),
          stroke: stroke,
          color: ringColor,
          softColor: c.orangeSoft,
          background: background ?? c.line.withValues(alpha: 0.55),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.stroke,
    required this.color,
    required this.softColor,
    required this.background,
  });

  final double progress;
  final double stroke;
  final Color color;
  final Color softColor;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = background,
    );

    if (progress <= 0) return;
    const start = -math.pi / 2;
    final sweep = math.pi * 2 * progress;

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 1.7
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawArc(rect, start, sweep, false, glow);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [softColor, color],
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, start, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.stroke != stroke;
  }
}

class MiniBars extends StatelessWidget {
  const MiniBars({
    super.key,
    required this.values,
    this.color,
    this.height = 46,
    this.barWidth = 5,
  });

  final List<double> values;
  final Color? color;
  final double height;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = color ?? c.orange;
    if (values.isEmpty) {
      return SizedBox(height: height);
    }
    final maxValue = values.reduce(math.max).clamp(1.0, 100.0);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            Container(
              width: barWidth,
              height: (values[i] / maxValue * height).clamp(3.0, height),
              decoration: BoxDecoration(
                color: accent.withValues(
                  alpha: 0.28 + (i / values.length) * 0.72,
                ),
                borderRadius: BorderRadius.circular(barWidth),
              ),
            ),
            if (i != values.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}
