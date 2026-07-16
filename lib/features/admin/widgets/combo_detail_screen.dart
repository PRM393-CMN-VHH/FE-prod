import 'package:flutter/material.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/admin/widgets/admin_common_widgets.dart';
import 'package:prm393/features/admin/widgets/combo_item_dialog.dart';
import 'package:prm393/features/catalog/models/product.dart';

class ComboDetailScreen extends StatefulWidget {
  final Product combo;

  const ComboDetailScreen({super.key, required this.combo});

  @override
  State<ComboDetailScreen> createState() => ComboDetailScreenState();
}

class ComboDetailScreenState extends State<ComboDetailScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getAdminComboItems(widget.combo.id);
  }

  void _refresh() {
    setState(() {
      _future = ApiService().getAdminComboItems(widget.combo.id);
    });
  }

  Future<void> _addItem(List products) async {
    final result = await showDialog<(int, int)>(
      context: context,
      builder: (_) => ComboItemDialog(products: products),
    );
    if (result == null) return;
    try {
      await ApiService().saveAdminComboItem(
        comboId: widget.combo.id,
        productId: result.$1,
        quantity: result.$2,
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      showAdminError(context, e);
    }
  }

  Future<void> _removeItem(int id) async {
    try {
      await ApiService().removeAdminComboItem(id);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      showAdminError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.combo.name)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdminLoading();
          }
          if (snapshot.hasError) {
            return AdminErrorState(error: snapshot.error!);
          }
          final data = snapshot.data!;
          final items =
              (data['comboItems'] ??
                      data['productComboItems'] ??
                      data['items'] ??
                      [])
                  as List;
          final products =
              (data['productList'] ?? data['products'] ?? []) as List;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              AdminCard(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: () => _addItem(products),
                  icon: const Icon(Icons.add),
                  label: const Text("Thêm hoa vào combo"),
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const AdminEmptyState(text: "Combo chưa có thành phần")
              else
                ...items.map((raw) {
                  final item = Map<String, dynamic>.from(raw as Map);
                  final product = item['component'] is Map
                      ? Map<String, dynamic>.from(item['component'] as Map)
                      : item['product'] is Map
                      ? Map<String, dynamic>.from(item['product'] as Map)
                      : <String, dynamic>{};
                  final id = item['id'] ?? item['comboItemId'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AdminCard(
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(12),
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
                                  product['productName'] ??
                                      product['name'] ??
                                      "Hoa #$id",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Số lượng: ${item['quantity'] ?? 0}",
                                  style: const TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeItem(id as int),
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
