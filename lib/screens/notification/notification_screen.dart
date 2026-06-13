import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/providers/notification_provider.dart';
import 'package:prm393/theme/app_theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProv = Provider.of<NotificationProvider>(context);
    final notifications = notifProv.notifications;
    final textTheme = Theme.of(context).textTheme;

    return Column(
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
                icon: const Icon(Icons.done_all, size: 18, color: AppTheme.primaryColor),
                label: const Text(
                  "Đánh dấu tất cả đã đọc",
                  style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        
        Expanded(
          child: notifProv.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                )
              : notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_none_outlined,
                            size: 80,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Không có thông báo",
                            style: textTheme.headlineSmall?.copyWith(color: AppTheme.textSecondaryColor),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Chúng tôi sẽ thông báo cho bạn khi có tin mới",
                            style: TextStyle(color: AppTheme.textSecondaryColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        
                        // Time calculation helper
                        final diff = DateTime.now().difference(notif.timestamp);
                        String timeText;
                        if (diff.inMinutes < 60) {
                          timeText = "${diff.inMinutes} phút trước";
                        } else if (diff.inHours < 24) {
                          timeText = "${diff.inHours} giờ trước";
                        } else {
                          timeText = "${diff.inDays} ngày trước";
                        }

                        return Card(
                          elevation: 0,
                          color: notif.isRead ? Colors.white : const Color(0xFFFDF6F8), // Warm pink tint for unread
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: notif.isRead ? Colors.grey.shade200 : AppTheme.primaryColor.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            onTap: () {
                              notifProv.markAsRead(notif.id);
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: notif.isRead 
                                    ? Colors.grey.shade100 
                                    : AppTheme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                notif.title.toLowerCase().contains("confirm") 
                                    ? Icons.receipt_long_outlined
                                    : Icons.local_florist,
                                color: notif.isRead ? Colors.grey : AppTheme.primaryColor,
                                size: 24,
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  timeText,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                notif.content,
                                style: TextStyle(
                                  color: notif.isRead ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            trailing: !notif.isRead
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
