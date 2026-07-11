import 'json_helpers.dart';

class TransactionSummary {
  final int month;
  final int year;
  final double totalIncome;
  final double totalExpense;
  final double net;
  final Map<String, double> byCategory;
  final double previousMonthExpense;

  TransactionSummary({
    required this.month,
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.byCategory,
    required this.previousMonthExpense,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    final rawByCategory = json['by_category'];
    final byCategory = <String, double>{};
    if (rawByCategory is Map) {
      rawByCategory.forEach((key, value) {
        byCategory[key.toString()] = toDouble(value);
      });
    }
    return TransactionSummary(
      month: toInt(json['month']),
      year: toInt(json['year']),
      totalIncome: toDouble(json['total_income']),
      totalExpense: toDouble(json['total_expense']),
      net: toDouble(json['net']),
      byCategory: byCategory,
      previousMonthExpense: toDouble(json['previous_month_expense']),
    );
  }
}
