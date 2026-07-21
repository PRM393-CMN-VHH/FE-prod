import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/features/orders/models/order.dart';
import 'package:prm393/features/orders/screens/order_detail_screen.dart';
import 'package:prm393/core/utils/status_translator.dart';

class OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function(OrderModel order)? onCancel;
  final Future<void> Function(OrderModel order)? onRepay;
  final Future<void> Function(OrderModel order)? onConfirmReceived;

  const OrderList({
    super.key,
    required this.orders,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    this.onCancel,
    this.onRepay,
    this.onConfirmReceived,
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
          const finalStatuses = ['cancelled', 'delivered', 'completed'];
          final canCancel =
              onCancel != null &&
              order.paymentStatus.toLowerCase() != 'paid' &&
              !finalStatuses.contains(order.status.toLowerCase());
          final canRepay =
              onRepay != null &&
              order.paymentStatus.toLowerCase() != 'paid' &&
              !finalStatuses.contains(order.status.toLowerCase());
          final canConfirmReceived =
              onConfirmReceived != null &&
              order.status.toLowerCase() == 'delivered';

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
                          StatusTranslator.orderStatus(order.status),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Thanh toán: ${order.paymentMethod} ${order.paymentStatus.isEmpty ? '' : '(${StatusTranslator.paymentStatus(order.paymentStatus)})'}",
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
                    if (canCancel || canRepay || canConfirmReceived) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                            if (canConfirmReceived)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () => onConfirmReceived!(order),
                                child: const Text("Đã nhận hàng"),
                              ),
                            if (canRepay)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () => onRepay!(order),
                                child: const Text("Thanh toán"),
                              ),
                            if ((canRepay || canConfirmReceived) && canCancel)
                              const SizedBox(width: 8),
                            if (canCancel)
                              TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () => onCancel!(order),
                                child: const Text(
                                  "Hủy đơn",
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
