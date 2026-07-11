import '../models/app_notification.dart';
import 'api_client.dart';

class NotificationService {
  final _client = ApiClient.instance;

  Future<List<AppNotification>> getNotifications() async {
    final data = await _client.get('/notifications') as List;
    return data.map((e) => AppNotification.fromJson(e)).toList();
  }

  Future<void> markAsRead(int notificationId) async {
    await _client.patch('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _client.patch('/notifications/read-all');
  }

  Future<void> deleteNotification(int notificationId) async {
    await _client.delete('/notifications/$notificationId');
  }
}
