import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/providers/auth_provider.dart';
import 'package:prm393/providers/cart_provider.dart';
import 'package:prm393/providers/notification_provider.dart';
import 'package:prm393/providers/product_provider.dart';
import 'package:prm393/providers/chat_provider.dart';
import 'package:prm393/screens/product/product_list_screen.dart';
import 'package:prm393/screens/cart/cart_screen.dart';
import 'package:prm393/screens/map/map_screen.dart';
import 'package:prm393/screens/chat/chat_screen.dart';
import 'package:prm393/screens/notification/notification_screen.dart';
import 'package:prm393/theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ProductListScreen(),
    const CartScreen(),
    const MapScreen(),
    const ChatScreen(),
    const NotificationScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Fetch initial data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProv = Provider.of<ProductProvider>(context, listen: false);
      Provider.of<CartProvider>(context, listen: false).loadCart(productProv.products);
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
      Provider.of<ChatProvider>(context, listen: false).loadMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_florist, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              _currentIndex == 0 ? "Tiem Hoa Xinh" : 
              _currentIndex == 1 ? "Shopping Cart" :
              _currentIndex == 2 ? "Our Stores" :
              _currentIndex == 3 ? "Support Chat" : "Notifications",
              style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
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
                  title: const Text("Sign Out"),
                  content: const Text("Are you sure you want to log out from Tiem Hoa Xinh?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        authProvider.signOut();
                      },
                      child: const Text(
                        "Sign Out",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
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
            label: "Home",
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
            label: "Cart",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: "Stores",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(notificationProvider.unreadCount.toString()),
              isLabelVisible: notificationProvider.unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            activeIcon: Badge(
              label: Text(notificationProvider.unreadCount.toString()),
              isLabelVisible: notificationProvider.unreadCount > 0,
              child: const Icon(Icons.notifications),
            ),
            label: "Alerts",
          ),
        ],
      ),
    );
  }
}
