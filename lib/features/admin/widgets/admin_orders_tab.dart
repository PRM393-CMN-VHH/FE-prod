import 'package:flutter/material.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/features/admin/widgets/admin_common_widgets.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  final _emailController = TextEditingController();
  String? _status;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() {
    return ApiService().getAdminOrders(
      email: _emailController.text.trim(),
      status: _status,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _updateStatus(int orderId, String status) async {
    try {
      await ApiService().updateAdminOrderStatus(
        orderId: orderId,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã cập nhật trạng thái")));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      showAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: AdminCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Tìm theo email",
                    prefixIcon: Icon(Icons.search),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _refresh(),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: "Trạng thái đơn",
                    prefixIcon: Icon(Icons.filter_alt_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text("Tất cả")),
                    DropdownMenuItem(value: "PENDING", child: Text("PENDING")),
                    DropdownMenuItem(
                      value: "CONFIRMED",
                      child: Text("CONFIRMED"),
                    ),
                    DropdownMenuItem(value: "SHIPPED", child: Text("SHIPPED")),
                    DropdownMenuItem(
                      value: "DELIVERED",
                      child: Text("DELIVERED"),
                    ),
                    DropdownMenuItem(
                      value: "CANCELLED",
                      child: Text("CANCELLED"),
                    ),
                  ],
                  onChanged: (value) {
                    _status = value;
                    _refresh();
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AdminLoading();
              }
              if (snapshot.hasError) {
                return AdminErrorState(error: snapshot.error!);
              }

              final orders = snapshot.data!['orders'] as List? ?? [];
              if (orders.isEmpty) {
                return const AdminEmptyState(text: "Không có đơn");
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = Map<String, dynamic>.from(orders[index] as Map);
                  final orderId = order['orderId'] ?? order['id'] ?? 0;
                  final currentStatus =
                      (order['orderStatus'] ?? order['status'] ?? '')
                          .toString();
                  final user = order['user'] is Map
                      ? Map<String, dynamic>.from(order['user'] as Map)
                      : <String, dynamic>{};
                  final totalPrice = (order['totalPrice'] as num? ?? 0)
                      .toDouble();

                  return AdminCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Đơn #$orderId",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            AdminStatusChip(
                              label: currentStatus,
                              color: adminStatusColor(currentStatus),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.mail_outline,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                user['email']?.toString() ?? 'Không có email',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatVnd(totalPrice),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: PopupMenuButton<String>(
                            onSelected: (value) =>
                                _updateStatus(orderId as int, value),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: "PENDING",
                                child: Text("PENDING"),
                              ),
                              PopupMenuItem(
                                value: "CONFIRMED",
                                child: Text("CONFIRMED"),
                              ),
                              PopupMenuItem(
                                value: "SHIPPED",
                                child: Text("SHIPPED"),
                              ),
                              PopupMenuItem(
                                value: "DELIVERED",
                                child: Text("DELIVERED"),
                              ),
                              PopupMenuItem(
                                value: "CANCELLED",
                                child: Text("CANCELLED"),
                              ),
                            ],
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Cập nhật",
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.more_horiz,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
