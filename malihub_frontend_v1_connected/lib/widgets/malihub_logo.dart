import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The Malihub brand mark: a wallet glyph on a rounded forest-green square.
///
/// This is the same design exported as the Android launcher icon (see
/// /android_app_icon in the project root) — defined once here so every
/// screen (splash, onboarding, login, register) and the home-screen icon
/// stay visually identical.
class MalihubLogo extends StatelessWidget {
  final double size;
  final bool translucentBackground;

  const MalihubLogo(
      {super.key, this.size = 48, this.translucentBackground = false});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: translucentBackground
            ? Colors.white.withValues(alpha: 0.16)
            : AppColors.primary,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.56, size * 0.56),
          painter: _WalletGlyphPainter(),
        ),
      ),
    );
  }
}

/// Hand-drawn wallet glyph: body + fold line + clasp. Deliberately simple
/// geometry so it stays crisp at launcher-icon sizes down to 48px.
class _WalletGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()..color = Colors.white;
    final accentPaint = Paint()..color = AppColors.primary;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.14, w, h * 0.72),
      Radius.circular(w * 0.16),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Fold line
    final foldPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = h * 0.045;
    canvas.drawLine(
      Offset(w * 0.08, h * 0.40),
      Offset(w * 0.92, h * 0.40),
      foldPaint,
    );

    // Clasp
    canvas.drawCircle(Offset(w * 0.68, h * 0.55), w * 0.10, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
