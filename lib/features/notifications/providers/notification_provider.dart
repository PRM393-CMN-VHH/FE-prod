import 'dart:async';
import 'package:flutter/material.dart';
import 'package:prm393/features/notifications/models/app_notification.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/network/order_socket_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final OrderSocketService _socket = OrderSocketService.instance;
  StreamSubscription<OrderSocketEvent>? _socketSubscription;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  // One-shot stream of live-pushed notifications, for a top banner to show
  // regardless of which screen is open (separate from the persisted list above).
  final _bannerController = StreamController<NotificationModel>.broadcast();
  Stream<NotificationModel> get bannerStream => _bannerController.stream;

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
      unawaited(_connectSocket());
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  // Pushes new items into the list live instead of waiting for the next
  // manual loadNotifications() call (e.g. opening the notifications screen).
  Future<void> _connectSocket() async {
    final cookie = await _apiService.getSessionCookie();
    await _socket.connect(wsUrl: ApiService.wsOrdersUrl, cookie: cookie);
    _socketSubscription ??= _socket.events?.listen(_handleSocketEvent);
  }

  void _handleSocketEvent(OrderSocketEvent event) {
    NotificationModel? model;
    if (event.type == 'notification') {
      model = NotificationModel.fromJson(event.payload);
    } else if (event.type == 'new_order') {
      // Admin-only push (backend only broadcasts this to connected admins):
      // there's no persisted AppNotification for it, so synthesize a local,
      // negative-id entry the admin can tap straight through to the order.
      final orderId = event.payload['orderId'];
      final customerName = event.payload['customerName']?.toString() ?? '';
      model = NotificationModel(
        id: -DateTime.now().millisecondsSinceEpoch,
        title: "Đơn hàng mới #$orderId",
        content: customerName.isEmpty
            ? "Có đơn hàng mới vừa được đặt."
            : "$customerName vừa đặt một đơn hàng mới.",
        timestamp: DateTime.now(),
        isRead: false,
        orderId: orderId is int ? orderId : int.tryParse(orderId.toString()),
      );
    }
    if (model == null) return;
    _notifications.insert(0, model);
    notifyListeners();
    _bannerController.add(model);
  }

  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index < 0 || _notifications[index].isRead) return;

    // Cập nhật UI ngay, đồng bộ server phía sau
    _notifications[index].isRead = true;
    notifyListeners();
    // Negative ids are locally-synthesized "new_order" pushes with no
    // backing AppNotification row (see _handleSocketEvent) — nothing to sync.
    if (notificationId < 0) return;
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

  @override
  void dispose() {
    // Don't disconnect: OrderSocketService.instance is shared app-wide.
    _socketSubscription?.cancel();
    _bannerController.close();
    super.dispose();
  }
}
