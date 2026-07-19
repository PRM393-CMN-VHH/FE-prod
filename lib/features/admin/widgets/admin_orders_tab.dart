import 'package:flutter/material.dart';
import 'package:prm393/core/constants/app_messages.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/core/utils/status_translator.dart';
import 'package:prm393/features/admin/widgets/admin_common_widgets.dart';

const _orderStatuses = [
  "PENDING",
  "CONFIRMED",
  "SHIPPED",
  "DELIVERED",
  "CANCELLED",
];

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  final _emailController = TextEditingController();
  String? _status;
  int _page = 1;
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
      pageNo: _page,
    );
  }

  void _refresh({bool resetPage = true}) {
    setState(() {
      if (resetPage) _page = 1;
      _future = _load();
    });
  }

  Future<void> _changeStatus(int orderId, String currentStatus) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppMessage.adminChangeStatusTitle.text,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ..._orderStatuses.map((status) {
                final isCurrent = status == currentStatus;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isCurrent
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: adminStatusColor(status),
                  ),
                  title: Text(
                    StatusTranslator.orderStatus(status),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isCurrent
                          ? adminStatusColor(status)
                          : AppTheme.textPrimaryColor,
                    ),
                  ),
                  enabled: !isCurrent,
                  onTap: () => Navigator.pop(sheetContext, status),
                );
              }),
            ],
          ),
        ),
      ),
    );

    if (selected == null || !mounted) return;

    if (selected == "CANCELLED") {
      final confirmed = await confirmAdminAction(
        context,
        title: AppMessage.adminCancelOrderTitle.format([orderId]),
        message: AppMessage.adminCancelOrderMessage.text,
        confirmLabel: AppMessage.adminCancelOrderConfirm.text,
        destructive: true,
      );
      if (!confirmed) return;
    }

    try {
      await ApiService().updateAdminOrderStatus(
        orderId: orderId,
        status: selected,
      );
      if (!mounted) return;
      showAdminMessage(
        context,
        AppMessage.adminOrderStatusUpdated.format([orderId]),
      );
      _refresh(resetPage: false);
    } catch (e) {
      if (!mounted) return;
      showAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(
          controller: _emailController,
          hintText: "Tìm theo email khách hàng",
          onSubmitted: _refresh,
        ),
        AdminFilterChips(
          options: _orderStatuses,
          selected: _status,
          onSelected: (value) {
            _status = value;
            _refresh();
          },
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

              final data = snapshot.data!;
              final orders = data['orders'] as List? ?? [];
              final totalPage = (data['totalPage'] as num?)?.toInt() ?? 1;

              if (orders.isEmpty) {
                return AdminEmptyState(
                  text: AppMessage.adminEmptyOrders.text,
                  icon: Icons.receipt_long_outlined,
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = Map<String, dynamic>.from(
                          orders[index] as Map,
                        );
                        final orderId = order['orderId'] ?? order['id'] ?? 0;
                        final currentStatus =
                            (order['orderStatus'] ?? order['status'] ?? '')
                                .toString();
                        final paymentStatus = (order['paymentStatus'] ?? '')
                            .toString();
                        final user = order['user'] is Map
                            ? Map<String, dynamic>.from(order['user'] as Map)
                            : <String, dynamic>{};
                        final totalPrice = (order['totalPrice'] as num? ?? 0)
                            .toDouble();
                        final createdAt = order['createdAt']?.toString();

                        return AdminCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Đơn #$orderId",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  AdminStatusChip(
                                    label: StatusTranslator.orderStatus(currentStatus),
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
                                      user['email']?.toString() ??
                                          'Không có email',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (createdAt != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_outlined,
                                      size: 16,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatDate(createdAt),
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatVnd(totalPrice),
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (paymentStatus.isNotEmpty)
                                    AdminStatusChip(
                                      label: StatusTranslator.paymentStatus(paymentStatus),
                                      color: adminStatusColor(paymentStatus),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: () => _changeStatus(
                                    orderId as int,
                                    currentStatus,
                                  ),
                                  icon: const Icon(Icons.sync_alt, size: 16),
                                  label: const Text("Đổi trạng thái"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    side: const BorderSide(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  AdminPageControl(
                    page: _page,
                    hasMore: _page < totalPage,
                    onPrevious: () {
                      setState(() {
                        _page--;
                        _future = _load();
                      });
                    },
                    onNext: () {
                      setState(() {
                        _page++;
                        _future = _load();
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    return "$d/$m/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
  }
}
