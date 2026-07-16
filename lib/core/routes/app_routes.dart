import 'package:flutter/material.dart';
import 'package:prm393/app/auth_gate.dart';
import 'package:prm393/features/auth/screens/login_screen.dart';
import 'package:prm393/features/cart/screens/cart_order_screen.dart';
import 'package:prm393/features/catalog/screens/product_list_screen.dart';
import 'package:prm393/features/navigation/screens/main_navigation_screen.dart';
import 'package:prm393/features/profile/screens/profile_screen.dart';
import 'package:prm393/features/stores/screens/store_map_screen.dart';
import 'package:prm393/features/support/screens/support_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const auth = '/';
  static const login = '/login';
  static const main = '/main';
  static const products = '/products';
  static const cartOrders = '/cart-orders';
  static const profile = '/profile';
  static const stores = '/stores';
  static const support = '/support';

  static Map<String, WidgetBuilder> get routes => {
    auth: (_) => const AuthGate(),
    login: (_) => const LoginScreen(),
    main: (_) => const MainNavigation(),
    products: (_) => const ProductListScreen(),
    cartOrders: (_) => const CartOrderScreen(),
    profile: (_) => const ProfileScreen(),
    stores: (_) => const MapScreen(),
    support: (_) => const SupportScreen(),
  };
}
