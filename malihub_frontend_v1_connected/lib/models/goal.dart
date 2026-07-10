import 'json_helpers.dart';

class Goal {
  final int goalId;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;

  Goal({
    required this.goalId,
    required this.goalName,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        goalId: toInt(json['goal_id']),
        goalName: json['goal_name'] ?? '',
        targetAmount: toDouble(json['target_amount']),
        currentAmount: toDouble(json['current_amount']),
        deadline: toDateOrNull(json['deadline']),
      );
}
