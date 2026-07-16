import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/features/orders/models/order.dart';
import 'package:prm393/features/orders/providers/order_provider.dart';
import 'package:prm393/features/catalog/providers/product_provider.dart';
import 'package:prm393/features/orders/widgets/order_list.dart';
import 'package:prm393/features/cart/screens/vnpay_payment_screen.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/payment_navigation_signal.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final VoidCallback _paidOrdersListener;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
      Provider.of<OrderProvider>(
        context,
        listen: false,
      ).loadTransactionHistory();
    });
    _paidOrdersListener = () {
      if (!mounted) return;
      _tabController.animateTo(1);
      _loadOrders();
      Provider.of<OrderProvider>(
        context,
        listen: false,
      ).loadTransactionHistory();
    };
    paidOrdersRefreshSignal.addListener(_paidOrdersListener);
  }

  @override
  void dispose() {
    paidOrdersRefreshSignal.removeListener(_paidOrdersListener);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final products = Provider.of<ProductProvider>(
      context,
      listen: false,
    ).products;
    await Provider.of<OrderProvider>(
      context,
      listen: false,
    ).loadOrders(products);
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final products = Provider.of<ProductProvider>(
      context,
      listen: false,
    ).products;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final ok = await orderProvider.cancelOrder(order.id, products);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Đã hủy đơn #${order.id}"
              : orderProvider.errorMessage ?? "Không thể hủy đơn",
        ),
        backgroundColor: ok ? AppTheme.primaryColor : Colors.redAccent,
      ),
    );
  }

  Future<void> _repayOrder(OrderModel order) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final paymentUrl = await orderProvider.repayOrder(order.id);
    if (!mounted) return;
    if (paymentUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderProvider.errorMessage ?? "Không thể tạo thanh toán",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final orderNavigator = Navigator.of(context);
    final orderMessenger = ScaffoldMessenger.of(context);

    await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => VnpayPaymentScreen(
          paymentUrl: paymentUrl,
          onPaymentSuccess: (result) async {
            orderNavigator.pop();
            await _loadOrders();
            await orderProvider.loadTransactionHistory();
            if (!mounted) return;
            _tabController.animateTo(1);
            requestPaidOrdersView();
            orderMessenger.showSnackBar(
              const SnackBar(
                content: Text("Thanh toán thành công!"),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
          },
          onPaymentFail: (error) {
            orderNavigator.pop();
            orderMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  "Thanh toán thất bại: ${error['message'] ?? 'Đã hủy'}",
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          },
        ),
      ),
    );
    await _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: "Đơn hàng"),
            Tab(text: "Đã thanh toán"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              OrderList(
                orders: orderProvider.orders,
                isLoading: orderProvider.isLoading,
                errorMessage: orderProvider.errorMessage,
                onRefresh: _loadOrders,
                onCancel: _cancelOrder,
                onRepay: _repayOrder,
              ),
              OrderList(
                orders: orderProvider.paidTransactions,
                isLoading: orderProvider.isLoading,
                errorMessage: orderProvider.errorMessage,
                onRefresh: orderProvider.loadTransactionHistory,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
