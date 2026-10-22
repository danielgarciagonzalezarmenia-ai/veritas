import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

class VeritasMark extends StatelessWidget {
  const VeritasMark({super.key, this.size = 56, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: c.orange.withValues(alpha: 0.28),
                  blurRadius: size * 0.55,
                  spreadRadius: -size * 0.1,
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _MarkPainter(
          orange: c.orange,
          orangeSoft: c.orangeSoft,
          ember: c.ember,
          ink: c.bg,
          eye: c.text,
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.orange,
    required this.orangeSoft,
    required this.ember,
    required this.ink,
    required this.eye,
  });

  final Color orange;
  final Color orangeSoft;
  final Color ember;
  final Color ink;
  final Color eye;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.47;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..shader = SweepGradient(
        colors: [orangeSoft, orange, ember, orange, orangeSoft],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, ring);

    final inner = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [ink, Color.lerp(ink, ember, 0.35)!],
        center: const Alignment(-0.3, -0.5),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - size.width * 0.045, inner);

    final eyeWidth = size.width * 0.58;
    final eyeHeight = size.width * 0.27;
    final eyePath = Path()
      ..moveTo(center.dx - eyeWidth / 2, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy - eyeHeight,
        center.dx + eyeWidth / 2,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + eyeHeight,
        center.dx - eyeWidth / 2,
        center.dy,
      );
    canvas.drawPath(
      eyePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.035
        ..strokeCap = StrokeCap.round
        ..color = eye.withValues(alpha: 0.92),
    );

    final irisRadius = size.width * 0.135;
    final iris = Paint()
      ..shader = RadialGradient(
        colors: [orangeSoft, orange, ember],
        stops: const [0, 0.55, 1],
      ).createShader(Rect.fromCircle(center: center, radius: irisRadius));
    canvas.drawCircle(center, irisRadius, iris);

    canvas.drawCircle(
      center,
      irisRadius * 0.44,
      Paint()..color = ink.withValues(alpha: 0.95),
    );
    canvas.drawCircle(
      center + Offset(-irisRadius * 0.32, -irisRadius * 0.34),
      irisRadius * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    final scan = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - eyeWidth * 0.34, center.dy + eyeHeight * 0.72),
      Offset(center.dx + eyeWidth * 0.34, center.dy + eyeHeight * 0.72),
      scan,
    );
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) {
    return oldDelegate.orange != orange ||
        oldDelegate.eye != eye ||
        oldDelegate.ink != ink;
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.fontSize = 15, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'VERITAS',
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: fontSize * 0.34,
        color: color ?? context.colors.text,
      ),
    );
  }
}
