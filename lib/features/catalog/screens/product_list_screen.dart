import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/features/catalog/providers/product_provider.dart';
import 'package:prm393/features/catalog/screens/product_detail_screen.dart';
import 'package:prm393/features/catalog/widgets/filter_bottom_sheet.dart';
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
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm hoa...",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.textSecondaryColor,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  productProvider.setSearchQuery('');
                                  setState(() {});
                                },
                              )
                            : null,
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
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
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(16),
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

        // Categories list
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: productProvider.categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final catId = isAll
                  ? 0
                  : productProvider.categories[index - 1].id;
              final catName = isAll
                  ? "Tất cả"
                  : productProvider.categories[index - 1].name;
              final isSelected = productProvider.selectedCategoryId == catId;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    catName,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondaryColor,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: Colors.white,
                  disabledColor: Colors.white,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  onSelected: (_) {
                    productProvider.selectCategory(catId);
                  },
                ),
              );
            },
          ),
        ),

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
                ? Center(child: Text(productProvider.errorMessage!))
                : productProvider.filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      "Không tìm thấy sản phẩm phù hợp.",
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
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
