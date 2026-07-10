import 'json_helpers.dart';

/// Named AppNotification to avoid clashing with Flutter's own Notification class.
class AppNotification {
  final int notificationId;
  final String notificationType; // budget_exceeded | goal_milestone
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.notificationId,
    required this.notificationType,
    required this.message,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        notificationId: toInt(json['notification_id']),
        notificationType: json['notification_type'] ?? 'budget_exceeded',
        message: json['message'] ?? '',
        isRead: json['is_read'] ?? false,
        createdAt: toDateOrNull(json['created_at']),
      );
}
