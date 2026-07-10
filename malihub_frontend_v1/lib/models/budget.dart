import 'json_helpers.dart';

class Budget {
  final int budgetId;
  final int categoryId;
  final String? categoryName;
  final double budgetAmount;
  final String periodType; // weekly | monthly | yearly
  final DateTime startDate;
  final double? alertThreshold;
  final double spent;
  final double remaining;
  final int percentUsed;

  Budget({
    required this.budgetId,
    required this.categoryId,
    this.categoryName,
    required this.budgetAmount,
    required this.periodType,
    required this.startDate,
    this.alertThreshold,
    this.spent = 0,
    this.remaining = 0,
    this.percentUsed = 0,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    final categories = json['categories'];
    return Budget(
      budgetId: toInt(json['budget_id']),
      categoryId: toInt(json['category_id']),
      categoryName: categories is Map<String, dynamic>
          ? categories['category_name']
          : null,
      budgetAmount: toDouble(json['budget_amount']),
      periodType: json['period_type'] ?? 'monthly',
      startDate: toDateOrNull(json['start_date']) ?? DateTime.now(),
      alertThreshold: toDoubleOrNull(json['alert_threshold']),
      spent: toDouble(json['spent']),
      remaining: toDouble(json['remaining']),
      percentUsed: toInt(json['percent_used']),
    );
  }
}
