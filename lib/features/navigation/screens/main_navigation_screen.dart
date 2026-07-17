import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/core/constants/app_messages.dart';
import 'package:prm393/features/auth/providers/auth_provider.dart';
import 'package:prm393/features/cart/providers/cart_provider.dart';
import 'package:prm393/features/notifications/providers/notification_provider.dart';
import 'package:prm393/features/catalog/providers/product_provider.dart';
import 'package:prm393/features/chat/providers/chat_provider.dart';
import 'package:prm393/features/admin/providers/admin_chat_provider.dart';
import 'package:prm393/features/admin/screens/admin_screen.dart';
import 'package:prm393/features/catalog/screens/product_list_screen.dart';
import 'package:prm393/features/cart/screens/cart_order_screen.dart';
import 'package:prm393/features/profile/screens/profile_screen.dart';
import 'package:prm393/features/stores/screens/store_map_screen.dart';
import 'package:prm393/features/support/screens/support_screen.dart';
import 'package:prm393/core/constants/app_strings.dart';
import 'package:prm393/core/theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

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
    final screens = <Widget>[
      if (!isAdmin) const ProductListScreen(),
      if (!isAdmin) const CartOrderScreen(),
      if (isAdmin) const AdminScreen(),
      const ProfileScreen(),
      const MapScreen(),
      if (!isAdmin) const SupportScreen(),
    ];
    final titles = <String>[
      if (!isAdmin) AppStrings.appName,
      if (!isAdmin) AppStrings.cartAndOrders,
      if (isAdmin) AppStrings.admin,
      AppStrings.profile,
      AppStrings.stores,
      if (!isAdmin) AppStrings.support,
    ];
    if (_currentIndex >= screens.length) {
      _currentIndex = screens.length - 1;
    }

    return Scaffold(
      appBar: AppBar(
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
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              // Confirm logout
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(AppMessage.logoutTitle.text),
                  content: Text(AppMessage.logoutConfirmMessage.text),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(AppMessage.cancelAction.text),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        authProvider.signOut();
                      },
                      child: Text(
                        AppMessage.logoutTitle.text,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          if (!isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Trang chủ",
            ),
          if (!isAdmin)
            BottomNavigationBarItem(
              icon: Badge(
                label: Text(cartProvider.totalItemCount.toString()),
                isLabelVisible: cartProvider.totalItemCount > 0,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              activeIcon: Badge(
                label: Text(cartProvider.totalItemCount.toString()),
                isLabelVisible: cartProvider.totalItemCount > 0,
                child: const Icon(Icons.shopping_cart),
              ),
              label: "Giỏ/Đơn",
            ),
          if (isAdmin)
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: adminChatProvider.totalUnreadCount > 0,
                smallSize: 8,
                child: const Icon(Icons.admin_panel_settings_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: adminChatProvider.totalUnreadCount > 0,
                smallSize: 8,
                child: const Icon(Icons.admin_panel_settings),
              ),
              label: "Admin",
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
          if (!isAdmin)
            BottomNavigationBarItem(
              icon: Badge(
                label: Text(
                  (notificationProvider.unreadCount + chatProvider.unreadCount)
                      .toString(),
                ),
                isLabelVisible:
                    notificationProvider.unreadCount + chatProvider.unreadCount >
                    0,
                child: const Icon(Icons.chat_bubble_outline),
              ),
              activeIcon: Badge(
                label: Text(
                  (notificationProvider.unreadCount + chatProvider.unreadCount)
                      .toString(),
                ),
                isLabelVisible:
                    notificationProvider.unreadCount + chatProvider.unreadCount >
                    0,
                child: const Icon(Icons.chat_bubble),
              ),
              label: "Chat/Tin",
            ),
        ],
      ),
    );
  }
}
