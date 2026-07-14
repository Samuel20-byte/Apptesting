import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles LOCAL (on-device) notifications — e.g. budget threshold alerts.
/// No backend involved; these fire directly from the Flutter app.
///
/// Not to be confused with notification_service.dart, which fetches the
/// backend-driven notification inbox (getNotifications, markAsRead, etc).
class LocalNotificationService {
  LocalNotificationService._internal();
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Call this once, early in main() before runApp().
  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  /// Fires a notification immediately.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'budget_alerts_channel',
      'Budget Alerts',
      channelDescription:
          'Notifies you when you are close to or over a category budget.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }
}
