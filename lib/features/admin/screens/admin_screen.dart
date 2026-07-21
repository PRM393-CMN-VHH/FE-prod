import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/admin/providers/admin_chat_provider.dart';
import 'package:prm393/features/admin/widgets/admin_tabs.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadChat = context.watch<AdminChatProvider>().totalUnreadCount;

    return ColoredBox(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              tabs: [
                const Tab(
                  icon: Icon(Icons.dashboard_outlined, size: 18),
                  text: "Tổng quan",
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                const Tab(
                  icon: Icon(Icons.receipt_long_outlined, size: 18),
                  text: "Đơn hàng",
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                const Tab(
                  icon: Icon(Icons.local_florist_outlined, size: 18),
                  text: "Sản phẩm",
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                const Tab(
                  icon: Icon(Icons.people_outline, size: 18),
                  text: "User",
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Badge(
                    isLabelVisible: unreadChat > 0,
                    smallSize: 8,
                    child: const Icon(Icons.chat_bubble_outline, size: 18),
                  ),
                  text: "Chat",
                  iconMargin: const EdgeInsets.only(bottom: 4),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              children: const [
                AdminDashboardTab(),
                AdminOrdersTab(),
                AdminProductsTab(),
                AdminUsersTab(),
                AdminChatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
