import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../utils/formatters.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  bool _isLoading = true;
  String? _error;
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notifications = await _notificationService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load notifications.';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _notificationService.markAllAsRead();
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't reach the server.")));
    }
  }

  Future<void> _handleTap(AppNotification n) async {
    if (!n.isRead) {
      try {
        await _notificationService.markAsRead(n.notificationId);
        setState(() {
          _notifications = _notifications
              .map((existing) => existing.notificationId == n.notificationId
                  ? AppNotification(
                      notificationId: existing.notificationId,
                      notificationType: existing.notificationType,
                      message: existing.message,
                      isRead: true,
                      createdAt: existing.createdAt)
                  : existing)
              .toList();
        });
      } catch (_) {}
    }
  }

  (IconData, Color, Color, String) _presentation(String type) {
    switch (type) {
      case 'goal_milestone':
        return (Icons.emoji_events_outlined, AppColors.gold, AppColors.goldPale, 'Goal milestone');
      case 'budget_exceeded':
      default:
        return (Icons.warning_amber_rounded, AppColors.expense, AppColors.expensePale, 'Budget alert');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text('Notifications', style: AppText.sectionTitle),
                  const Spacer(),
                  if (unreadCount > 0)
                    TextButton(onPressed: _markAllRead, child: const Text('Mark all read', style: TextStyle(fontSize: 12, color: AppColors.primary))),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _isLoading
                    ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [
                        SizedBox(height: 250, child: Center(child: CircularProgressIndicator())),
                      ])
                    : _error != null
                        ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                            SizedBox(height: 250, child: Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))),
                          ])
                        : _notifications.isEmpty
                            ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [
                                SizedBox(height: 250, child: Center(child: Text("You're all caught up.", style: TextStyle(color: AppColors.textSecondary)))),
                              ])
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _notifications.length,
                                itemBuilder: (context, i) {
                                  final n = _notifications[i];
                                  final (icon, color, bg, label) = _presentation(n.notificationType);
                                  return InkWell(
                                    onTap: () => _handleTap(n),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: n.isRead ? AppColors.surface : AppColors.primaryPale.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: AppShadows.subtle,
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                                            child: Icon(icon, size: 18, color: color),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                                                const SizedBox(height: 4),
                                                Text(n.message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35)),
                                                const SizedBox(height: 6),
                                                Text(formatRelativeTime(n.createdAt), style: AppText.caption),
                                              ],
                                            ),
                                          ),
                                          if (!n.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(top: 4),
                                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
