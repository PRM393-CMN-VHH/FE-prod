import 'package:flutter/material.dart';
import 'package:prm393/core/constants/app_messages.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/core/utils/status_translator.dart';
import 'package:prm393/features/admin/widgets/admin_common_widgets.dart';
import 'package:prm393/features/orders/screens/order_detail_screen.dart';

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

class _AdminOrdersTabState extends State<AdminOrdersTab>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  late final TabController _tabController;
  final ValueNotifier<int> _refreshNotifier = ValueNotifier<int>(0);
  String _searchEmail = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _orderStatuses.length + 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tabController.dispose();
    _refreshNotifier.dispose();
    super.dispose();
  }

  void _submitSearch() {
    setState(() {
      _searchEmail = _emailController.text.trim();
    });
    _refreshNotifier.value++;
  }

  void _onOrderUpdated() {
    _refreshNotifier.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(
          controller: _emailController,
          hintText: "Tìm theo email khách hàng",
          onSubmitted: _submitSearch,
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabAlignment: TabAlignment.start,
          tabs: [
            const Tab(text: "Tất cả"),
            for (final status in _orderStatuses)
              Tab(text: StatusTranslator.orderStatus(status)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              AdminOrderList(
                status: null,
                searchEmail: _searchEmail,
                refreshNotifier: _refreshNotifier,
                onOrderUpdated: _onOrderUpdated,
              ),
              for (final status in _orderStatuses)
                AdminOrderList(
                  status: status,
                  searchEmail: _searchEmail,
                  refreshNotifier: _refreshNotifier,
                  onOrderUpdated: _onOrderUpdated,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminOrderList extends StatefulWidget {
  final String? status;
  final String searchEmail;
  final ValueNotifier<int> refreshNotifier;
  final VoidCallback onOrderUpdated;

  const AdminOrderList({
    super.key,
    required this.status,
    required this.searchEmail,
    required this.refreshNotifier,
    required this.onOrderUpdated,
  });

  @override
  State<AdminOrderList> createState() => _AdminOrderListState();
}

class _AdminOrderListState extends State<AdminOrderList>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _page = 1;
  int _totalPage = 1;
  // Payment-status sub-filter, only shown for the "Chờ xử lý" (PENDING) tab —
  // that's where knowing whether a pending order has already been paid
  // (e.g. via VNPay) matters most to the admin.
  String? _paymentStatusFilter;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier.addListener(_handleExternalRefresh);
    _load();
  }

  @override
  void didUpdateWidget(AdminOrderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchEmail != widget.searchEmail) {
      _page = 1;
      _load();
    }
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_handleExternalRefresh);
    super.dispose();
  }

  void _handleExternalRefresh() {
    _page = 1;
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    _errorMessage = null;
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final data = await ApiService().getAdminOrders(
        email: widget.searchEmail,
        status: widget.status,
        paymentStatus: widget.status == "PENDING" ? _paymentStatusFilter : null,
        pageNo: _page,
      );
      final fetched = List<dynamic>.from(data['orders'] as List? ?? []);
      // Backend doesn't accept a sort param, so this only orders items
      // within the current page — not guaranteed correct across pages.
      fetched.sort((a, b) {
        final aDate = DateTime.tryParse((a as Map)['createdAt']?.toString() ?? '');
        final bDate = DateTime.tryParse((b as Map)['createdAt']?.toString() ?? '');
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });
      if (mounted) {
        setState(() {
          _orders = fetched;
          _totalPage = (data['totalPage'] as num?)?.toInt() ?? 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToPage(int page) {
    if (page == _page) return;
    _page = page;
    _load();
  }

  void _setPaymentStatusFilter(String? paymentStatus) {
    if (paymentStatus == _paymentStatusFilter) return;
    _paymentStatusFilter = paymentStatus;
    _page = 1;
    _load();
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
      widget.onOrderUpdated();
    } catch (e) {
      if (!mounted) return;
      showAdminError(context, e);
    }
  }

  String _formatDate(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    return "$d/$m/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildPaymentStatusFilter() {
    const options = <String?, String>{
      null: "Tất cả",
      "UNPAID": "Chưa thanh toán",
      "PAID": "Đã thanh toán",
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: List.generate(options.length, (index) {
          final paymentStatus = options.keys.elementAt(index);
          final label = options[paymentStatus]!;
          final isSelected = paymentStatus == _paymentStatusFilter;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
                right: index == options.length - 1 ? 0 : 4,
              ),
              child: ChoiceChip(
                label: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => _setPaymentStatusFilter(paymentStatus),
                selectedColor: AppTheme.primaryColor,
                showCheckmark: false,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final paymentStatusFilterBar = widget.status == "PENDING"
        ? _buildPaymentStatusFilter()
        : null;

    if (_isLoading) {
      return Column(
        children: [
          ?paymentStatusFilterBar,
          const Expanded(child: AdminLoading()),
        ],
      );
    }
    if (_errorMessage != null && _orders.isEmpty) {
      return Column(
        children: [
          ?paymentStatusFilterBar,
          Expanded(child: AdminErrorState(error: _errorMessage!)),
        ],
      );
    }
    if (_orders.isEmpty) {
      return Column(
        children: [
          ?paymentStatusFilterBar,
          Expanded(
            child: AdminEmptyState(
              text: AppMessage.adminEmptyOrders.text,
              icon: Icons.receipt_long_outlined,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ?paymentStatusFilterBar,
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: _orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = Map<String, dynamic>.from(_orders[index] as Map);
              final orderId = order['orderId'] ?? order['id'] ?? 0;
              final currentStatus =
                  (order['orderStatus'] ?? order['status'] ?? '').toString();
              final paymentStatus = (order['paymentStatus'] ?? '').toString();
              final user = order['user'] is Map
                  ? Map<String, dynamic>.from(order['user'] as Map)
                  : <String, dynamic>{};
              final totalPrice = (order['totalPrice'] as num? ?? 0).toDouble();
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
                            style: Theme.of(context).textTheme.titleMedium,
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
                            user['email']?.toString() ?? 'Không có email',
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            label: StatusTranslator.paymentStatus(
                              paymentStatus,
                            ),
                            color: adminStatusColor(paymentStatus),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailScreen(
                                    orderId: orderId as int,
                                    isAdmin: true,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility_outlined, size: 14),
                            label: const Text(
                              "Xem chi tiết",
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondaryColor,
                              side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _changeStatus(orderId as int, currentStatus),
                            icon: const Icon(Icons.sync_alt, size: 14),
                            label: const Text(
                              "Đổi trạng thái",
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(color: AppTheme.primaryColor, width: 1.2),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
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
          hasMore: _page < _totalPage,
          onPrevious: () => _goToPage(_page - 1),
          onNext: () => _goToPage(_page + 1),
        ),
      ],
    );
  }
}
