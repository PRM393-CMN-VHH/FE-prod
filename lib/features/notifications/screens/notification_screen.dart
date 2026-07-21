import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/features/auth/providers/auth_provider.dart';
import 'package:prm393/features/notifications/providers/notification_provider.dart';
import 'package:prm393/features/notifications/widgets/empty_notifications.dart';
import 'package:prm393/features/notifications/widgets/notification_tile.dart';
import 'package:prm393/features/orders/screens/order_detail_screen.dart';
import 'package:prm393/core/theme/app_theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProv = Provider.of<NotificationProvider>(context);
    final notifications = notifProv.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Thông báo",
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Action Bar for notifications management
          if (notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    notifProv.markAllAsRead();
                  },
                  icon: const Icon(
                    Icons.done_all,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  label: const Text(
                    "Đánh dấu tất cả đã đọc",
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          Expanded(
            child: notifProv.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : notifications.isEmpty
                ? const EmptyNotifications()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return NotificationTile(
                        notification: notif,
                        onTap: () {
                          notifProv.markAsRead(notif.id);
                          if (notif.orderId != null) {
                            final isAdmin =
                                context.read<AuthProvider>().user?.isAdmin ??
                                false;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                  orderId: notif.orderId!,
                                  isAdmin: isAdmin,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
