import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutSlice {
  final String label;
  final double value;
  final Color color;

  DonutSlice({required this.label, required this.value, required this.color});
}

/// Hand-drawn donut chart (no chart package dependency) — multiple slices
/// sharing the same ring language as [RingProgress] elsewhere in the app.
class DonutChart extends StatelessWidget {
  final List<DonutSlice> slices;
  final double size;
  final double strokeWidth;

  const DonutChart({super.key, required this.slices, this.size = 160, this.strokeWidth = 22});

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _DonutPainter(slices: slices, total: total, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> slices;
  final double total;
  final double strokeWidth;

  _DonutPainter({required this.slices, required this.total, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    double startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweep = total == 0 ? 0.0 : (slice.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
