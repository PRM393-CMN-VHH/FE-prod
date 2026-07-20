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
              Tab(
                text: StatusTranslator.orderStatus(status),
              ),
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
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _orders = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _page = 1;
  int _totalPage = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.refreshNotifier.addListener(_handleExternalRefresh);
    _initialLoad();
  }

  @override
  void didUpdateWidget(AdminOrderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchEmail != widget.searchEmail) {
      _initialLoad();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    widget.refreshNotifier.removeListener(_handleExternalRefresh);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Trigger load more when the user scrolls near the bottom (200px threshold)
    if (maxScroll - currentScroll <= 200) {
      _loadMore();
    }
  }

  void _handleExternalRefresh() {
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    if (!mounted) return;
    
    _page = 1;
    _errorMessage = null;

    if (!_isInitialLoading) {
      setState(() {
        _isInitialLoading = true;
      });
    }

    try {
      final data = await ApiService().getAdminOrders(
        email: widget.searchEmail,
        status: widget.status,
        pageNo: 1,
      );
      final fetched = data['orders'] as List? ?? [];
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
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isInitialLoading || _isLoadingMore || _page >= _totalPage) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final nextPage = _page + 1;
      final data = await ApiService().getAdminOrders(
        email: widget.searchEmail,
        status: widget.status,
        pageNo: nextPage,
      );
      final newOrders = data['orders'] as List? ?? [];
      setState(() {
        _page = nextPage;
        _orders.addAll(newOrders);
        _totalPage = (data['totalPage'] as num?)?.toInt() ?? 1;
      });
    } catch (e) {
      if (mounted) showAdminError(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isInitialLoading) {
      return const AdminLoading();
    }
    if (_errorMessage != null && _orders.isEmpty) {
      return AdminErrorState(error: _errorMessage!);
    }
    if (_orders.isEmpty) {
      return AdminEmptyState(
        text: AppMessage.adminEmptyOrders.text,
        icon: Icons.receipt_long_outlined,
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _orders.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            ),
          );
        }

        final order = Map<String, dynamic>.from(
          _orders[index] as Map,
        );
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
    );
  }
}
