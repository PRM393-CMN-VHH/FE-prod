import 'package:flutter/material.dart';
import 'package:prm393/models/notification.dart';
import 'package:prm393/services/api_service.dart';

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
    if (index >= 0) {
      _notifications[index].isRead = true;
      notifyListeners();
      await _apiService.saveNotifications(_notifications);
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await _apiService.saveNotifications(_notifications);
  }

  Future<void> triggerNotification(String title, String content) async {
    await _apiService.addNotification(title: title, content: content);
    await loadNotifications();
  }
}
