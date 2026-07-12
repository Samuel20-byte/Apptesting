import 'json_helpers.dart';

class Category {
  final int categoryId;
  final String categoryName;
  final String? icon;
  final bool isDefault;
  final String categoryType; // 'income' or 'expense'

  Category({
    required this.categoryId,
    required this.categoryName,
    this.icon,
    this.isDefault = false,
    required this.categoryType,
  });

  /// Mirrors the `isIncome` getter already used on Transaction elsewhere
  /// in the app, so screens can filter categories the same way.
  bool get isIncome => categoryType == 'income';

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        categoryId: toInt(json['category_id']),
        categoryName: json['category_name'] ?? '',
        icon: json['icon'],
        isDefault: json['is_default'] ?? false,
        categoryType: json['category_type'] ?? 'expense',
      );
}
