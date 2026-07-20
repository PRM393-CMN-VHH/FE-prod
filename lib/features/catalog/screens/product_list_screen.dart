import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/features/catalog/providers/product_provider.dart';
import 'package:prm393/features/catalog/screens/product_detail_screen.dart';
import 'package:prm393/features/catalog/widgets/filter_bottom_sheet.dart';
import 'package:prm393/features/catalog/widgets/category_picker_sheet.dart';
import 'package:prm393/features/catalog/widgets/product_card.dart';
import 'package:prm393/core/theme/app_theme.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return const FilterBottomSheet();
      },
    );
  }

  void _showCategoryPicker(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return CategoryPickerSheet(
          categories: productProvider.categories,
          selectedCategoryId: productProvider.selectedCategoryId,
          onSelected: productProvider.selectCategory,
        );
      },
    );
  }

  String? _selectedCategoryName(ProductProvider productProvider) {
    if (productProvider.selectedCategoryId == 0) return null;
    for (final category in productProvider.categories) {
      if (category.id == productProvider.selectedCategoryId) return category.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor, width: 2.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          padding: const EdgeInsets.only(left: 4, right: 4),
                          color: Colors.white,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.menu,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                tooltip: "Chọn dịp",
                                onPressed: () => _showCategoryPicker(context),
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                  Icons.search,
                                  color: AppTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: "Tìm kiếm hoa...",
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                    _searchDebounce?.cancel();
                                    _searchDebounce = Timer(
                                      const Duration(milliseconds: 350),
                                      () {
                                        productProvider.setSearchQuery(value);
                                      },
                                    );
                                  },
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: AppTheme.textSecondaryColor,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    productProvider.setSearchQuery('');
                                    setState(() {});
                                  },
                                )
                              else
                                const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor, width: 2.0),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune, color: Colors.white),
                      onPressed: () => _showFilterSheet(context),
                    ),
                  ),
                ],
              ),
              if (productProvider.suggestions.isNotEmpty &&
                  _searchController.text.trim().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: productProvider.suggestions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final suggestion = productProvider.suggestions[index];
                      final id = int.tryParse('${suggestion['id']}') ?? 0;
                      final name = suggestion['name']?.toString() ?? '';
                      final imageUrl = suggestion['imageUrl']?.toString() ?? '';
                      return ListTile(
                        dense: true,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.local_florist),
                          ),
                        ),
                        title: Text(name),
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          final product = await productProvider
                              .loadProductDetail(id);
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        if (_selectedCategoryName(productProvider) != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(_selectedCategoryName(productProvider)!),
                onDeleted: () => productProvider.selectCategory(0),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: AppTheme.primaryColor),
                deleteIconColor: AppTheme.primaryColor,
              ),
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Main Products grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => productProvider.loadCatalog(),
            color: AppTheme.primaryColor,
            child: productProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : productProvider.errorMessage != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            Text(
                              productProvider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => productProvider.loadCatalog(),
                              child: const Text("Thử lại"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : productProvider.filteredProducts.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 180),
                      Center(
                        child: Text(
                          "Không tìm thấy sản phẩm phù hợp.",
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: productProvider.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
