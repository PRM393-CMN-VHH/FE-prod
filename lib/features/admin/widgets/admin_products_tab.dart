import 'package:flutter/material.dart';
import 'package:prm393/core/constants/app_messages.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/features/admin/widgets/admin_common_widgets.dart';
import 'package:prm393/features/admin/widgets/product_editor_screen.dart';
import 'package:prm393/features/catalog/models/product.dart';

const _lowStockThreshold = 5;

class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  final _searchController = TextEditingController();
  int _page = 1;
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
      pageNo: _page,
    );
  }

  void _refresh({bool resetPage = true}) {
    setState(() {
      if (resetPage) _page = 1;
      _future = _load();
    });
  }

  Future<void> _editProduct([Product? product]) async {
    final saved = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductEditorScreen(product: product),
      ),
    );
    if (saved == null) return;
    try {
      if (product == null) {
        await ApiService().addAdminProduct(saved);
        if (mounted) {
          showAdminMessage(context, AppMessage.adminProductAdded.text);
        }
      } else {
        await ApiService().editAdminProduct(saved);
        if (mounted) {
          showAdminMessage(context, AppMessage.adminProductUpdated.text);
        }
      }
      _refresh(resetPage: product == null);
    } catch (e) {
      if (!mounted) return;
      showAdminError(context, e);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await confirmAdminAction(
      context,
      title: AppMessage.adminDeleteProductTitle.text,
      message: AppMessage.adminDeleteProductMessage.format([product.name]),
      confirmLabel: AppMessage.adminDeleteConfirm.text,
      destructive: true,
    );
    if (!confirmed) return;

    try {
      await ApiService().deleteAdminProduct(product.id);
      if (!mounted) return;
      showAdminMessage(
        context,
        AppMessage.adminProductDeleted.format([product.name]),
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
          controller: _searchController,
          hintText: "Tìm sản phẩm theo tên",
          onSubmitted: _refresh,
          trailing: SizedBox(
            width: 50,
            height: 50,
            child: FilledButton(
              onPressed: () => _editProduct(),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.add),
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

              final data = snapshot.data!;
              final products = (data['products'] as List? ?? [])
                  .map((json) => Product.fromJson(json as Map<String, dynamic>))
                  .toList();
              final totalPage = (data['totalPage'] as num?)?.toInt() ?? 1;

              if (products.isEmpty) {
                return AdminEmptyState(
                  text: AppMessage.adminEmptyProducts.text,
                  icon: Icons.local_florist_outlined,
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final isLowStock = product.stock <= _lowStockThreshold;
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Giá gốc: ${formatVnd(product.price)}",
                                      style: const TextStyle(
                                        color: AppTheme.textPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (product.promoPrice != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        "Giá KM: ${formatVnd(product.promoPrice!)}",
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          "Tồn kho: ${product.stock}",
                                          style: const TextStyle(
                                            color:
                                                AppTheme.textSecondaryColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (isLowStock) ...[
                                          const SizedBox(width: 8),
                                          AdminStatusChip(
                                            label: "Sắp hết hàng",
                                            color: AdminPalette.warning,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () =>
                                              _editProduct(product),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                          ),
                                          label: const Text("Sửa"),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _deleteProduct(product),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            foregroundColor:
                                                AdminPalette.danger,
                                          ),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                          ),
                                          label: const Text("Xóa"),
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
}
