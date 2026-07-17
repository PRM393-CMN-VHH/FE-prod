import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/features/chat/providers/chat_provider.dart';
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
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      Provider.of<ChatProvider>(context, listen: false).markAsRead();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadChat = context.watch<ChatProvider>().unreadCount;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: unreadChat > 0,
                smallSize: 8,
                child: const Icon(Icons.chat_bubble_outline),
              ),
              text: "Chat",
            ),
            const Tab(text: "Tin", icon: Icon(Icons.notifications_outlined)),
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
