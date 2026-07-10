import 'json_helpers.dart';

/// transactionType: "debit" = expense (money out), "credit" = income (money in).
/// This convention matches the backend's signedAmount() helper.
class Transaction {
  final int transactionId;
  final int accountId;
  final int categoryId;
  final double amount;
  final String transactionType; // debit | credit
  final String? description;
  final DateTime? transactionDate;
  final String? categoryName;
  final String? accountName;

  Transaction({
    required this.transactionId,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.transactionType,
    this.description,
    this.transactionDate,
    this.categoryName,
    this.accountName,
  });

  bool get isIncome => transactionType == 'credit';

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final categories = json['categories'];
    final accounts = json['accounts'];
    return Transaction(
      transactionId: toInt(json['transaction_id']),
      accountId: toInt(json['account_id']),
      categoryId: toInt(json['category_id']),
      amount: toDouble(json['amount']),
      transactionType: json['transaction_type'] ?? 'debit',
      description: json['description'],
      transactionDate: toDateOrNull(json['transaction_date']),
      categoryName: categories is Map<String, dynamic>
          ? categories['category_name']
          : null,
      accountName:
          accounts is Map<String, dynamic> ? accounts['account_name'] : null,
    );
  }
}
