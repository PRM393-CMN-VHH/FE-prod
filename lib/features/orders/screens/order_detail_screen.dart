import 'package:flutter/material.dart';
import 'package:prm393/features/orders/models/order.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/core/utils/error_translator.dart';
import 'package:prm393/features/orders/widgets/order_info_tile.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<OrderModel> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getOrderDetail(widget.orderId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ApiService().getOrderDetail(widget.orderId);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Đơn #${widget.orderId}")),
      body: FutureBuilder<OrderModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  ErrorTranslator.userMessage(snapshot.error!),
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final order = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppTheme.primaryColor,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OrderInfoTile(label: "Trạng thái đơn", value: order.status),
                OrderInfoTile(
                  label: "Thanh toán",
                  value:
                      "${order.paymentMethod}${order.paymentStatus.isEmpty ? '' : ' (${order.paymentStatus})'}",
                ),
                OrderInfoTile(label: "Người nhận", value: order.recipientName),
                OrderInfoTile(
                  label: "Số điện thoại",
                  value: order.recipientPhone,
                ),
                OrderInfoTile(label: "Địa chỉ", value: order.shippingAddress),
                OrderInfoTile(
                  label: "Ngày tạo",
                  value:
                      "${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}",
                ),
                const SizedBox(height: 12),
                Text(
                  "Sản phẩm",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (order.items.isEmpty)
                  const Text(
                    "Không có chi tiết sản phẩm.",
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  )
                else
                  ...order.items.map(
                    (item) => Card(
                      elevation: 0,
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.product.imageUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.local_florist),
                          ),
                        ),
                        title: Text(item.product.name),
                        subtitle: Text("Số lượng: ${item.quantity}"),
                        trailing: Text(formatVnd(item.price * item.quantity)),
                      ),
                    ),
                  ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Tổng cộng",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formatVnd(order.totalAmount),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
