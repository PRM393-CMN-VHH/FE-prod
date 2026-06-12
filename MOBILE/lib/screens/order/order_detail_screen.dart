import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/models/order.dart';
import 'package:prm393/providers/auth_provider.dart';
import 'package:prm393/services/api_service.dart';
import 'package:prm393/theme/app_theme.dart';
import 'package:prm393/utils/currency_formatter.dart';
import 'package:prm393/utils/error_translator.dart';

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

  Future<void> _updateStatus(String status) async {
    try {
      await ApiService().updateAdminOrderStatus(
        orderId: widget.orderId,
        status: status,
      );
      if (mounted) {
        ErrorTranslator.showTopToast(context, "Cập nhật trạng thái thành công!", isError: false);
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ErrorTranslator.showTopToast(context, ErrorTranslator.userMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        Provider.of<AuthProvider>(context, listen: false).user?.isAdmin ??
        false;

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
                if (isAdmin) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Cập nhật trạng thái:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: [
                          "PENDING",
                          "CONFIRMED",
                          "SHIPPED",
                          "DELIVERED",
                          "CANCELLED",
                        ].contains(order.status.toUpperCase())
                            ? order.status.toUpperCase()
                            : null,
                        hint: Text(order.status),
                        items: const [
                          DropdownMenuItem(
                            value: "PENDING",
                            child: Text("PENDING"),
                          ),
                          DropdownMenuItem(
                            value: "CONFIRMED",
                            child: Text("CONFIRMED"),
                          ),
                          DropdownMenuItem(
                            value: "SHIPPED",
                            child: Text("SHIPPED"),
                          ),
                          DropdownMenuItem(
                            value: "DELIVERED",
                            child: Text("DELIVERED"),
                          ),
                          DropdownMenuItem(
                            value: "CANCELLED",
                            child: Text("CANCELLED"),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) _updateStatus(val);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                ],
                _InfoTile(label: "Trạng thái đơn", value: order.status),
                _InfoTile(
                  label: "Thanh toán",
                  value:
                      "${order.paymentMethod}${order.paymentStatus.isEmpty ? '' : ' (${order.paymentStatus})'}",
                ),
                if (order.userEmail != null)
                  _InfoTile(label: "Tài khoản đặt", value: order.userEmail!),
                _InfoTile(label: "Người nhận", value: order.recipientName),
                _InfoTile(label: "Số điện thoại", value: order.recipientPhone),
                _InfoTile(label: "Địa chỉ", value: order.shippingAddress),
                _InfoTile(
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

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
