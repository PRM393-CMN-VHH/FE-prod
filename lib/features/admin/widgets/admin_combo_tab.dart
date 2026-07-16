import 'package:flutter/material.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/features/admin/widgets/admin_common_widgets.dart';
import 'package:prm393/features/admin/widgets/combo_detail_screen.dart';
import 'package:prm393/features/catalog/models/product.dart';

class AdminComboTab extends StatefulWidget {
  const AdminComboTab({super.key});

  @override
  State<AdminComboTab> createState() => _AdminComboTabState();
}

class _AdminComboTabState extends State<AdminComboTab> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getAdminComboProducts();
  }

  void _refresh() {
    setState(() {
      _future = ApiService().getAdminComboProducts();
    });
  }

  Future<void> _openCombo(Product combo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComboDetailScreen(combo: combo)),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoading();
        }
        if (snapshot.hasError) {
          return AdminErrorState(error: snapshot.error!);
        }
        final combos = snapshot.data ?? [];
        if (combos.isEmpty) {
          return const AdminEmptyState(text: "Không có combo");
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          itemCount: combos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final combo = combos[index];
            return AdminCard(
              onTap: () => _openCombo(combo),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_florist_outlined,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          combo.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatVnd(combo.price),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondaryColor,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
