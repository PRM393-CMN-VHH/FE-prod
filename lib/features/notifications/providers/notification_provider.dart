import 'package:flutter/material.dart';
import 'package:prm393/features/notifications/models/app_notification.dart';
import 'package:prm393/core/network/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _apiService.getNotifications();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index < 0 || _notifications[index].isRead) return;

    // Cập nhật UI ngay, đồng bộ server phía sau
    _notifications[index].isRead = true;
    notifyListeners();
    try {
      await _apiService.markNotificationRead(notificationId);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    try {
      await _apiService.markAllNotificationsRead();
    } catch (_) {}
  }
}
