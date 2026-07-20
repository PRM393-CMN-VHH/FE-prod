import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/features/auth/providers/auth_provider.dart';
import 'package:prm393/features/cart/providers/cart_provider.dart';
import 'package:prm393/features/notifications/providers/notification_provider.dart';
import 'package:prm393/features/catalog/providers/product_provider.dart';
import 'package:prm393/features/chat/providers/chat_provider.dart';
import 'package:prm393/features/admin/providers/admin_chat_provider.dart';
import 'package:prm393/features/admin/widgets/admin_tabs.dart';
import 'package:prm393/features/catalog/screens/product_list_screen.dart';
import 'package:prm393/features/orders/screens/order_screen.dart';
import 'package:prm393/features/cart/screens/cart_screen.dart';
import 'package:prm393/features/profile/screens/profile_screen.dart';
import 'package:prm393/features/stores/screens/store_map_screen.dart';
import 'package:prm393/features/support/screens/support_screen.dart';
import 'package:prm393/features/notifications/screens/notification_screen.dart';
import 'package:prm393/core/constants/app_strings.dart';
import 'package:prm393/core/theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  // Tabs load their own data in initState, so IndexedStack must only build a
  // tab's real screen once it's actually been visited — otherwise every tab
  // (orders, store map, ...) fires its API calls immediately on app start
  // just because IndexedStack keeps all children mounted.
  final Set<int> _visitedTabIndices = {0};

  @override
  void initState() {
    super.initState();
    // Fetch initial data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProv = Provider.of<ProductProvider>(context, listen: false);
      Provider.of<CartProvider>(
        context,
        listen: false,
      ).loadCart(productProv.products);
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).loadNotifications();

      final isAdmin =
          Provider.of<AuthProvider>(context, listen: false).user?.isAdmin ??
          false;
      if (isAdmin) {
        Provider.of<AdminChatProvider>(
          context,
          listen: false,
        ).loadConversations();
      } else {
        Provider.of<ChatProvider>(context, listen: false).loadMessages();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final adminChatProvider = Provider.of<AdminChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.isAdmin ?? false;

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final screens = isAdmin
        ? const <Widget>[
            AdminDashboardTab(),
            AdminOrdersTab(),
            AdminProductsTab(),
            AdminUsersTab(),
            AdminChatTab(),
          ]
        : const <Widget>[
            ProductListScreen(),
            OrderScreen(),
            ProfileScreen(),
            MapScreen(),
            SupportScreen(),
          ];

    final titles = isAdmin
        ? const <String>[
            "Tổng quan",
            "Đơn hàng",
            "Sản phẩm",
            "User",
            "Chat",
          ]
        : <String>[
            AppStrings.appName,
            AppStrings.cartAndOrders,
            AppStrings.profile,
            AppStrings.stores,
            AppStrings.support,
          ];

    if (_currentIndex >= screens.length) {
      _currentIndex = screens.length - 1;
    }

    return Scaffold(
      appBar: (!isAdmin && _currentIndex == 4)
          ? null
          : AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_florist, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    titles[_currentIndex],
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                if (isAdmin) ...[
                  IconButton(
                    icon: const Icon(Icons.map_outlined),
                    tooltip: "Bản đồ cửa hàng",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            backgroundColor: AppTheme.backgroundColor,
                            appBar: AppBar(title: const Text("Bản đồ cửa hàng")),
                            body: const MapScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    tooltip: "Hồ sơ cá nhân",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            backgroundColor: AppTheme.backgroundColor,
                            appBar: AppBar(title: const Text("Hồ sơ")),
                            body: const ProfileScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  IconButton(
                    icon: Badge(
                      label: Text(notificationProvider.unreadCount.toString()),
                      isLabelVisible: notificationProvider.unreadCount > 0,
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Badge(
                      label: Text(cartProvider.totalItemCount.toString()),
                      isLabelVisible: cartProvider.totalItemCount > 0,
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(width: 8),
              ],
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < screens.length; i++)
            _visitedTabIndices.contains(i) ? screens[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: isKeyboardOpen
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                  _visitedTabIndices.add(index);
                });
                // Mark chat messages as read when navigating to SupportScreen (index 4 for non-admin)
                if (!isAdmin && index == 4) {
                  Provider.of<ChatProvider>(context, listen: false).markAsRead();
                }
              },
              items: isAdmin
                  ? [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.dashboard_outlined),
                        activeIcon: Icon(Icons.dashboard),
                        label: "Tổng quan",
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.receipt_long_outlined),
                        activeIcon: Icon(Icons.receipt_long),
                        label: "Đơn hàng",
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.local_florist_outlined),
                        activeIcon: Icon(Icons.local_florist),
                        label: "Sản phẩm",
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.people_outline),
                        activeIcon: Icon(Icons.people),
                        label: "User",
                      ),
                      BottomNavigationBarItem(
                        icon: Badge(
                          isLabelVisible: adminChatProvider.totalUnreadCount > 0,
                          smallSize: 8,
                          child: const Icon(Icons.chat_bubble_outline),
                        ),
                        activeIcon: Badge(
                          isLabelVisible: adminChatProvider.totalUnreadCount > 0,
                          smallSize: 8,
                          child: const Icon(Icons.chat_bubble),
                        ),
                        label: "Chat",
                      ),
                    ]
                  : [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined),
                        activeIcon: Icon(Icons.home),
                        label: "Trang chủ",
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.receipt_long_outlined),
                        activeIcon: Icon(Icons.receipt_long),
                        label: "Đơn hàng",
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline),
                        activeIcon: Icon(Icons.person),
                        label: "Hồ sơ",
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.map_outlined),
                        activeIcon: Icon(Icons.map),
                        label: "Cửa hàng",
                      ),
                      BottomNavigationBarItem(
                        icon: Badge(
                          label: Text(chatProvider.unreadCount.toString()),
                          isLabelVisible: chatProvider.unreadCount > 0,
                          child: const Icon(Icons.chat_bubble_outline),
                        ),
                        activeIcon: Badge(
                          label: Text(chatProvider.unreadCount.toString()),
                          isLabelVisible: chatProvider.unreadCount > 0,
                          child: const Icon(Icons.chat_bubble),
                        ),
                        label: "Hỗ trợ",
                      ),
                    ],
            ),
    );
  }
}
