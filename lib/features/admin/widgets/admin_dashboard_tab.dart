import 'package:flutter/material.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/admin/widgets/admin_common_widgets.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getAdminDashboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ApiService().getAdminDashboard();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoading();
        }
        if (snapshot.hasError) {
          return AdminErrorState(error: snapshot.error!);
        }
        final data = snapshot.data!;
        final stats = [
          (
            "Khách hàng",
            data['totalUsers'],
            Icons.people_outline,
            Colors.blue.shade700,
          ),
          (
            "Sản phẩm",
            data['totalProducts'],
            Icons.local_florist_outlined,
            AppTheme.primaryColor,
          ),
          (
            "Đơn hàng",
            data['totalOrders'],
            Icons.receipt_long_outlined,
            Colors.indigo.shade700,
          ),
          (
            "Pending",
            data['pendingCount'],
            Icons.hourglass_empty,
            Colors.orange.shade800,
          ),
          (
            "Confirmed",
            data['confirmedCount'],
            Icons.verified_outlined,
            Colors.blue.shade700,
          ),
          (
            "Shipped",
            data['shippedCount'],
            Icons.local_shipping_outlined,
            Colors.indigo.shade700,
          ),
          (
            "Delivered",
            data['deliveredCount'],
            Icons.check_circle_outline,
            Colors.green.shade700,
          ),
          (
            "Cancelled",
            data['cancelledCount'],
            Icons.cancel_outlined,
            Colors.red.shade700,
          ),
        ];
        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppTheme.primaryColor,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: stats.length,
            itemBuilder: (_, index) {
              final stat = stats[index];
              return AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: stat.$4.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(stat.$3, color: stat.$4, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      "${stat.$2 ?? 0}",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
