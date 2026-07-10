import '../models/budget.dart';
import 'api_client.dart';

class BudgetService {
  final _client = ApiClient.instance;

  Future<List<Budget>> getBudgets() async {
    final data = await _client.get('/budgets') as List;
    return data.map((e) => Budget.fromJson(e)).toList();
  }

  Future<Budget> createBudget({
    required int categoryId,
    required double budgetAmount,
    required String periodType, // weekly | monthly | yearly
    required DateTime startDate,
    double? alertThreshold,
  }) async {
    final data = await _client.post('/budgets', body: {
      'category_id': categoryId,
      'budget_amount': budgetAmount,
      'period_type': periodType,
      'start_date': startDate.toIso8601String().split('T').first,
      if (alertThreshold != null) 'alert_threshold': alertThreshold,
    });
    return Budget.fromJson(data);
  }

  Future<Budget> updateBudget({
    required int budgetId,
    double? budgetAmount,
    String? periodType,
    DateTime? startDate,
    double? alertThreshold,
  }) async {
    final data = await _client.put('/budgets/$budgetId', body: {
      if (budgetAmount != null) 'budget_amount': budgetAmount,
      if (periodType != null) 'period_type': periodType,
      if (startDate != null) 'start_date': startDate.toIso8601String().split('T').first,
      if (alertThreshold != null) 'alert_threshold': alertThreshold,
    });
    return Budget.fromJson(data);
  }

  Future<void> deleteBudget(int budgetId) async {
    await _client.delete('/budgets/$budgetId');
  }
}
