import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Malihub's signature visual element: a circular progress ring.
///
/// Used for budget usage, savings goals, and category breakdowns — the
/// same ring language everywhere reinforces "hub" as a literal shape, not
/// just a word in the app name. Deliberately the one recurring flourish;
/// everything else in the app stays quiet around it.
class RingProgress extends StatelessWidget {
  final double progress; // 0.0 - 1.0+
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? center;

  const RingProgress({
    super.key,
    required this.progress,
    this.size = 64,
    this.strokeWidth = 8,
    this.color = AppColors.primary,
    this.trackColor = AppColors.surfaceSunken,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0).toDouble(),
              color: color,
              trackColor: trackColor,
              strokeWidth: strokeWidth,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
