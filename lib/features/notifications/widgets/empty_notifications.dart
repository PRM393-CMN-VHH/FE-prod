import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';

class EmptyNotifications extends StatelessWidget {
  const EmptyNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
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
            "No notifications",
            style: textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We will alert you here when something fresh arrives",
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}
