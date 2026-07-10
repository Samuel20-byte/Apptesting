import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Small tile showing a labelled figure, e.g. "Total Income".
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;
  final Color? iconBackground;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    this.icon,
    this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBackground ?? AppColors.primaryPale,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: valueColor),
            ),
          if (icon != null) const SizedBox(height: 8),
          Text(value, style: AppText.displayMedium.copyWith(fontSize: 18, color: valueColor)),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}
