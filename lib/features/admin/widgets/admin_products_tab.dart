import 'package:flutter/material.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/features/admin/widgets/admin_common_widgets.dart';
import 'package:prm393/features/admin/widgets/product_editor_dialog.dart';
import 'package:prm393/features/catalog/models/product.dart';

class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  final _searchController = TextEditingController();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() {
    return ApiService().getAdminProducts(
      keyword: _searchController.text.trim(),
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _editProduct([Product? product]) async {
    final saved = await showDialog<Product>(
      context: context,
      builder: (_) => ProductEditorDialog(product: product),
    );
    if (saved == null) return;
    try {
      if (product == null) {
        await ApiService().addAdminProduct(saved);
      } else {
        await ApiService().editAdminProduct(saved);
      }
      _refresh();
    } catch (e) {
      if (!mounted) return;
      showAdminError(context, e);
    }
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      await ApiService().deleteAdminProduct(productId);
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: "Tìm sản phẩm",
                      prefixIcon: Icon(Icons.search),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _refresh(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => _editProduct(),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.add),
                  ),
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

              final products = (snapshot.data!['products'] as List? ?? [])
                  .map((json) => Product.fromJson(json as Map<String, dynamic>))
                  .toList();
              if (products.isEmpty) {
                return const AdminEmptyState(text: "Không có sản phẩm");
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return AdminCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            product.imageUrl,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 76,
                              height: 76,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.08,
                              ),
                              child: const Icon(Icons.local_florist),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatVnd(product.price),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tồn kho: ${product.stock}",
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _editProduct(product),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    label: const Text("Sửa"),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteProduct(product.id),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.redAccent,
                                  ),
                                ],
                              ),
                            ],
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
