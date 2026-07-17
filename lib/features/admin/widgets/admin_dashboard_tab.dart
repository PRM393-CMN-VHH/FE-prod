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

        final totals = [
          (
            "Khách hàng",
            data['totalUsers'],
            Icons.people_outline,
            AdminPalette.info,
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
            AdminPalette.progress,
          ),
        ];

        final pending = (data['pendingCount'] as num?)?.toInt() ?? 0;
        final confirmed = (data['confirmedCount'] as num?)?.toInt() ?? 0;
        final shipped = (data['shippedCount'] as num?)?.toInt() ?? 0;
        final delivered = (data['deliveredCount'] as num?)?.toInt() ?? 0;
        final cancelled = (data['cancelledCount'] as num?)?.toInt() ?? 0;
        final totalForRatio =
            pending + confirmed + shipped + delivered + cancelled;

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppTheme.primaryColor,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              const AdminSectionHeader(title: "Tổng quan"),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: totals.length,
                itemBuilder: (_, index) {
                  final stat = totals[index];
                  return AdminStatCard(
                    label: stat.$1,
                    value: stat.$2,
                    icon: stat.$3,
                    color: stat.$4,
                  );
                },
              ),
              const SizedBox(height: 24),
              const AdminSectionHeader(title: "Đơn hàng theo trạng thái"),
              AdminCard(
                child: Column(
                  children: [
                    AdminStatusBreakdownRow(
                      label: "Chờ xử lý",
                      count: pending,
                      total: totalForRatio,
                      color: AdminPalette.warning,
                      icon: Icons.hourglass_empty,
                    ),
                    AdminStatusBreakdownRow(
                      label: "Đã xác nhận",
                      count: confirmed,
                      total: totalForRatio,
                      color: AdminPalette.info,
                      icon: Icons.verified_outlined,
                    ),
                    AdminStatusBreakdownRow(
                      label: "Đang giao",
                      count: shipped,
                      total: totalForRatio,
                      color: AdminPalette.progress,
                      icon: Icons.local_shipping_outlined,
                    ),
                    AdminStatusBreakdownRow(
                      label: "Đã giao",
                      count: delivered,
                      total: totalForRatio,
                      color: AdminPalette.success,
                      icon: Icons.check_circle_outline,
                    ),
                    AdminStatusBreakdownRow(
                      label: "Đã hủy",
                      count: cancelled,
                      total: totalForRatio,
                      color: AdminPalette.danger,
                      icon: Icons.cancel_outlined,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
