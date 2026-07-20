import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/features/orders/models/order.dart';
import 'package:prm393/features/orders/providers/order_provider.dart';
import 'package:prm393/features/catalog/providers/product_provider.dart';
import 'package:prm393/features/orders/widgets/order_list.dart';
import 'package:prm393/features/cart/screens/vnpay_payment_screen.dart';
import 'package:prm393/core/constants/app_messages.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/status_translator.dart';

// Tab 0 = "Tất cả" (no status filter). "Đã giao" covers both DELIVERED
// (shop marked it delivered) and COMPLETED (customer confirmed receipt) —
// COMPLETED isn't a separate tab, it's just a further step within "Đã giao".
// Each entry is fetched from the backend via GET /order/my-orders?status=...
// (comma-separated when a tab covers more than one backend status).
const List<String?> _orderStatusFilters = [
  null,
  'PENDING',
  'CONFIRMED',
  'SHIPPED',
  'DELIVERED,COMPLETED',
  'CANCELLED',
];

String _tabLabel(String? status) {
  if (status == null) return "Tất cả";
  if (status == 'DELIVERED,COMPLETED') return "Đã giao";
  return StatusTranslator.orderStatus(status);
}

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Set<String?> _fetchedStatuses = {};

  String? get _currentStatus {
    final index = _tabController.index;
    return index < _orderStatusFilters.length
        ? _orderStatusFilters[index]
        : null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _orderStatusFilters.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders(status: null);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final status = _orderStatusFilters[_tabController.index];
    if (_fetchedStatuses.contains(status)) return;
    _loadOrders(status: status);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders({required String? status}) async {
    final products = Provider.of<ProductProvider>(
      context,
      listen: false,
    ).products;
    _fetchedStatuses.add(status);
    await Provider.of<OrderProvider>(
      context,
      listen: false,
    ).loadOrders(products, status: status);
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final products = Provider.of<ProductProvider>(
      context,
      listen: false,
    ).products;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final ok = await orderProvider.cancelOrder(
      order.id,
      products,
      currentStatus: _currentStatus,
    );
    if (!mounted) return;
    // Cancelling clears the whole cache — force a re-fetch next time each
    // other tab is revisited.
    _fetchedStatuses
      ..clear()
      ..add(_currentStatus);
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

  Future<void> _confirmReceived(OrderModel order) async {
    final products = Provider.of<ProductProvider>(
      context,
      listen: false,
    ).products;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final ok = await orderProvider.confirmReceived(
      order.id,
      products,
      currentStatus: _currentStatus,
    );
    if (!mounted) return;
    _fetchedStatuses
      ..clear()
      ..add(_currentStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Đã xác nhận nhận hàng cho đơn #${order.id}. Giờ bạn có thể đánh giá sản phẩm!"
              : orderProvider.errorMessage ?? "Không thể xác nhận",
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
            _fetchedStatuses.clear();
            await _loadOrders(status: _currentStatus);
            orderMessenger.showSnackBar(
              SnackBar(
                content: Text(AppMessage.paymentSuccessTitle.text),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
          },
          onPaymentFail: (error) {
            orderNavigator.pop();
            orderMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  AppMessage.paymentFailed.format([
                    error['message'] ??
                        AppMessage.paymentCancelledFallback.text,
                  ]),
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          },
        ),
      ),
    );
    _fetchedStatuses.remove(_currentStatus);
    await _loadOrders(status: _currentStatus);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabAlignment: TabAlignment.start,
          tabs: [
            for (final status in _orderStatusFilters)
              Tab(text: _tabLabel(status)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              for (final status in _orderStatusFilters)
                OrderList(
                  orders: orderProvider.ordersFor(status),
                  isLoading: orderProvider.isLoadingStatus(status),
                  errorMessage: orderProvider.errorMessage,
                  onRefresh: () => _loadOrders(status: status),
                  onCancel: _cancelOrder,
                  onRepay: _repayOrder,
                  onConfirmReceived: _confirmReceived,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
