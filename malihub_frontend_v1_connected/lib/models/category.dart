import 'json_helpers.dart';

class Category {
  final int categoryId;
  final String categoryName;
  final String? icon;
  final bool isDefault;

  Category({
    required this.categoryId,
    required this.categoryName,
    this.icon,
    this.isDefault = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        categoryId: toInt(json['category_id']),
        categoryName: json['category_name'] ?? '',
        icon: json['icon'],
        isDefault: json['is_default'] ?? false,
      );
}
