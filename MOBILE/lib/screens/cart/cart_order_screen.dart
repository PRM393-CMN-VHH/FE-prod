import 'package:flutter/material.dart';
import 'package:prm393/screens/cart/cart_screen.dart';
import 'package:prm393/screens/order/order_screen.dart';
import 'package:prm393/theme/app_theme.dart';
import 'package:prm393/utils/payment_navigation_signal.dart';

class CartOrderScreen extends StatefulWidget {
  const CartOrderScreen({super.key});

  @override
  State<CartOrderScreen> createState() => _CartOrderScreenState();
}

class _CartOrderScreenState extends State<CartOrderScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final VoidCallback _paidOrdersListener;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _paidOrdersListener = () {
      if (mounted) {
        _tabController.animateTo(1);
      }
    };
    paidOrdersRefreshSignal.addListener(_paidOrdersListener);
  }

  @override
  void dispose() {
    paidOrdersRefreshSignal.removeListener(_paidOrdersListener);
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
            Tab(text: "Giỏ hàng", icon: Icon(Icons.shopping_cart_outlined)),
            Tab(text: "Đơn hàng", icon: Icon(Icons.receipt_long_outlined)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [CartScreen(), OrderScreen()],
          ),
        ),
      ],
    );
  }
}
