import 'package:flutter/material.dart';
import 'package:prm393/features/chat/screens/chat_screen.dart';
import 'package:prm393/features/notifications/screens/notification_screen.dart';
import 'package:prm393/core/theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: "Chat", icon: Icon(Icons.chat_bubble_outline)),
            Tab(text: "Tin", icon: Icon(Icons.notifications_outlined)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [ChatScreen(), NotificationScreen()],
          ),
        ),
      ],
    );
  }
}
