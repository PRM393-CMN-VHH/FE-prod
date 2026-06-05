import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/providers/auth_provider.dart';
import 'package:prm393/providers/cart_provider.dart';
import 'package:prm393/providers/notification_provider.dart';
import 'package:prm393/providers/product_provider.dart';
import 'package:prm393/providers/chat_provider.dart';
import 'package:prm393/screens/product/product_list_screen.dart';
import 'package:prm393/screens/cart/cart_order_screen.dart';
import 'package:prm393/screens/profile/profile_screen.dart';
import 'package:prm393/screens/map/map_screen.dart';
import 'package:prm393/screens/support/support_screen.dart';
import 'package:prm393/theme/app_theme.dart';

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
      Provider.of<ChatProvider>(context, listen: false).loadMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final screens = <Widget>[
      const ProductListScreen(),
      const CartOrderScreen(),
      const ProfileScreen(),
      const MapScreen(),
      const SupportScreen(),
    ];
    final titles = <String>[
      "Tiệm Hoa Xnh",
      "Giỏ & Đơn hàng",
      "Hồ sơ",
      "Cửa hàng",
      "Chat & Tin",
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
                  title: const Text("Đăng xuất"),
                  content: const Text(
                    "Bạn có chắc muốn đăng xuất khỏi Tiệm Hoa Xnh?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Hủy"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        authProvider.signOut();
                      },
                      child: const Text(
                        "Đăng xuất",
                        style: TextStyle(color: Colors.redAccent),
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
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Trang chủ",
          ),
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
              label: Text(notificationProvider.unreadCount.toString()),
              isLabelVisible: notificationProvider.unreadCount > 0,
              child: const Icon(Icons.chat_bubble_outline),
            ),
            activeIcon: Badge(
              label: Text(notificationProvider.unreadCount.toString()),
              isLabelVisible: notificationProvider.unreadCount > 0,
              child: const Icon(Icons.chat_bubble),
            ),
            label: "Chat/Tin",
          ),
        ],
      ),
    );
  }
}
