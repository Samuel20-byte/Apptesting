import '../models/transaction.dart';
import '../models/transaction_summary.dart';
import 'api_client.dart';

class TransactionService {
  final _client = ApiClient.instance;

  Future<List<Transaction>> getTransactions({int? limit, int? offset}) async {
    final data = await _client.get('/transactions', query: {
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    }) as List;
    return data.map((e) => Transaction.fromJson(e)).toList();
  }

  Future<Transaction> createTransaction({
    required int accountId,
    required int categoryId,
    required double amount,
    required String transactionType, // debit | credit
    String? description,
    DateTime? transactionDate,
  }) async {
    final data = await _client.post('/transactions', body: {
      'account_id': accountId,
      'category_id': categoryId,
      'amount': amount,
      'transaction_type': transactionType,
      if (description != null && description.isNotEmpty) 'description': description,
      if (transactionDate != null)
        'transaction_date': transactionDate.toIso8601String(),
    });
    return Transaction.fromJson(data);
  }

  Future<Transaction> updateTransaction({
    required int transactionId,
    int? categoryId,
    double? amount,
    String? transactionType,
    String? description,
    DateTime? transactionDate,
  }) async {
    final data = await _client.put('/transactions/$transactionId', body: {
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (transactionType != null) 'transaction_type': transactionType,
      if (description != null) 'description': description,
      if (transactionDate != null)
        'transaction_date': transactionDate.toIso8601String(),
    });
    return Transaction.fromJson(data);
  }

  Future<void> deleteTransaction(int transactionId) async {
    await _client.delete('/transactions/$transactionId');
  }

  Future<TransactionSummary> getSummary({int? month, int? year}) async {
    final data = await _client.get('/transactions/summary', query: {
      if (month != null) 'month': month,
      if (year != null) 'year': year,
    });
    return TransactionSummary.fromJson(data);
  }
}
