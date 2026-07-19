import 'package:prm393/features/notifications/models/app_notification.dart';
import 'package:prm393/core/network/api_client_base.dart';

/// Server-side notifications, per user.
mixin NotificationApi on ApiClientBase {
  Future<List<NotificationModel>> getNotifications() async {
    final response = await request(ApiEndpoints.notifications);
    if (response is List) {
      return response
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }
    throw Exception("Invalid notifications response from server");
  }

  Future<void> markNotificationRead(int notificationId) async {
    await request(ApiEndpoints.notificationRead, params: {'id': notificationId});
  }

  Future<void> markAllNotificationsRead() async {
    await request(ApiEndpoints.notificationsReadAll);
  }
}
