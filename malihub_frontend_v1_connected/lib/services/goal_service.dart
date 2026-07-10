import '../models/goal.dart';
import 'api_client.dart';

class GoalService {
  final _client = ApiClient.instance;

  Future<List<Goal>> getGoals() async {
    final data = await _client.get('/goals') as List;
    return data.map((e) => Goal.fromJson(e)).toList();
  }

  Future<Goal> createGoal({
    required String goalName,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
  }) async {
    final data = await _client.post('/goals', body: {
      'goal_name': goalName,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      if (deadline != null) 'deadline': deadline.toIso8601String().split('T').first,
    });
    return Goal.fromJson(data);
  }

  Future<Goal> updateGoal({
    required int goalId,
    String? goalName,
    double? targetAmount,
    DateTime? deadline,
  }) async {
    final data = await _client.put('/goals/$goalId', body: {
      if (goalName != null) 'goal_name': goalName,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (deadline != null) 'deadline': deadline.toIso8601String().split('T').first,
    });
    return Goal.fromJson(data);
  }

  Future<Goal> contribute({required int goalId, required double amount}) async {
    final data = await _client.patch('/goals/$goalId/contribute', body: {
      'amount': amount,
    });
    return Goal.fromJson(data);
  }

  Future<void> deleteGoal(int goalId) async {
    await _client.delete('/goals/$goalId');
  }
}
