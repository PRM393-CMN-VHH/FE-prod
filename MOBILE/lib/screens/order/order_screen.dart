import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/models/order.dart';
import 'package:prm393/providers/order_provider.dart';
import 'package:prm393/providers/product_provider.dart';
import 'package:prm393/screens/order/order_detail_screen.dart';
import 'package:prm393/screens/cart/vnpay_payment_screen.dart';
import 'package:prm393/theme/app_theme.dart';
import 'package:prm393/utils/currency_formatter.dart';
import 'package:prm393/utils/error_translator.dart';
import 'package:prm393/utils/payment_navigation_signal.dart';

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
    // Thêm hộp thoại xác nhận xóa
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa vĩnh viễn đơn hàng #${order.id} không? Thao tác này không thể hoàn tác."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Quay lại"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Đồng ý xóa", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final products = Provider.of<ProductProvider>(
      context,
      listen: false,
    ).products;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final ok = await orderProvider.deleteOrder(order.id, products);
    if (!mounted) return;
    ErrorTranslator.showTopToast(
      context,
      ok
          ? "Đã xóa đơn #${order.id}"
          : orderProvider.errorMessage ?? "Không thể xóa đơn",
      isError: !ok,
    );
  }

  Future<void> _repayOrder(OrderModel order) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final paymentUrl = await orderProvider.repayOrder(order.id);
    if (!mounted) return;
    if (paymentUrl == null) {
      ErrorTranslator.showTopToast(
        context,
        orderProvider.errorMessage ?? "Không thể tạo thanh toán",
      );
      return;
    }

    final orderNavigator = Navigator.of(context);

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
            ErrorTranslator.showTopToast(context, "Thanh toán thành công!", isError: false);
          },
          onPaymentFail: (error) {
            orderNavigator.pop();
            ErrorTranslator.showTopToast(
              context,
              "Thanh toán thất bại: ${error['message'] ?? 'Đã hủy'}",
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
            Tab(text: "Đang xử lý"),
            Tab(text: "Lịch sử mua"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _OrderList(
                orders: orderProvider.orders,
                isLoading: orderProvider.isLoading,
                errorMessage: orderProvider.errorMessage,
                onRefresh: _loadOrders,
                onCancel: _cancelOrder,
                onRepay: _repayOrder,
              ),
              _OrderList(
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

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function(OrderModel order)? onCancel;
  final Future<void> Function(OrderModel order)? onRepay;

  const _OrderList({
    required this.orders,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    this.onCancel,
    this.onRepay,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (errorMessage != null && orders.isEmpty) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppTheme.primaryColor,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Center(
              child: Text(
                "Chưa có đơn hàng",
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          final statusUpper = order.status.toUpperCase();
          final canCancel = onCancel != null &&
              order.paymentStatus.toLowerCase() != 'paid' &&
              (statusUpper == 'PENDING' ||
                  statusUpper == 'CONFIRMED' ||
                  statusUpper == 'CONFIRM' ||
                  statusUpper == 'CANCELLED');
          final canRepay =
              onRepay != null && order.paymentStatus.toLowerCase() != 'paid' && statusUpper != 'CANCELLED';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(orderId: order.id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Đơn #${order.id}",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          order.status,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Thanh toán: ${order.paymentMethod} ${order.paymentStatus.isEmpty ? '' : '(${order.paymentStatus})'}",
                    ),
                    const SizedBox(height: 4),
                    Text("Tổng tiền: ${formatVnd(order.totalAmount)}"),
                    if (order.items.isNotEmpty) ...[
                      const Divider(height: 24),
                      ...order.items
                          .take(3)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                "${item.product.name} x${item.quantity}",
                              ),
                            ),
                          ),
                    ],
                    if (canCancel || canRepay) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (canRepay)
                            OutlinedButton(
                              onPressed: () => onRepay!(order),
                              child: const Text("Thanh toán"),
                            ),
                          if (canRepay && canCancel) const SizedBox(width: 8),
                          if (canCancel)
                            TextButton(
                              onPressed: () => onCancel!(order),
                              child: const Text(
                                "Xóa đơn",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
