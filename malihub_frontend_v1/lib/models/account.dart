import 'json_helpers.dart';

class Account {
  final int accountId;
  final String accountName;
  final String accountType; // checking | savings | credit_card | cash
  final double balance;
  final bool isActive;

  Account({
    required this.accountId,
    required this.accountName,
    required this.accountType,
    required this.balance,
    this.isActive = true,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        accountId: toInt(json['account_id']),
        accountName: json['account_name'] ?? '',
        accountType: json['account_type'] ?? 'cash',
        balance: toDouble(json['balance']),
        isActive: json['is_active'] ?? true,
      );
}
