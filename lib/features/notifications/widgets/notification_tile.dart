import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/notifications/models/app_notification.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final diff = DateTime.now().difference(notification.timestamp);
    final timeText = diff.inMinutes < 60
        ? "${diff.inMinutes}m ago"
        : diff.inHours < 24
        ? "${diff.inHours}h ago"
        : "${diff.inDays}d ago";

    return Card(
      elevation: 0,
      color: notification.isRead ? Colors.white : const Color(0xFFFDF6F8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.isRead
              ? Colors.grey.shade200
              : AppTheme.primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.grey.shade100
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            notification.title.toLowerCase().contains("confirm")
                ? Icons.receipt_long_outlined
                : Icons.local_florist,
            color: notification.isRead ? Colors.grey : AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: notification.isRead
                      ? FontWeight.normal
                      : FontWeight.bold,
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
            notification.content,
            style: TextStyle(
              color: notification.isRead
                  ? AppTheme.textSecondaryColor
                  : AppTheme.textPrimaryColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        trailing: !notification.isRead
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
  }
}
