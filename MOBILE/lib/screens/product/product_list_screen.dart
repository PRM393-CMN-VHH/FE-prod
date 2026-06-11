import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/providers/product_provider.dart';
import 'package:prm393/screens/product/product_detail_screen.dart';
import 'package:prm393/theme/app_theme.dart';
import 'package:prm393/utils/currency_formatter.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm hoa...",
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondaryColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textSecondaryColor),
                            onPressed: () {
                              _searchController.clear();
                              productProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
                      productProvider.setSearchQuery(value);
                    });
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
              final catId = isAll ? 0 : productProvider.categories[index - 1].id;
              final catName = isAll ? "Tất cả" : productProvider.categories[index - 1].name;
              final isSelected = productProvider.selectedCategoryId == catId;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    catName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
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
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : productProvider.errorMessage != null
                    ? Center(
                        child: Text(productProvider.errorMessage!),
                      )
                    : productProvider.filteredProducts.isEmpty
                        ? const Center(
                            child: Text(
                              "Không tìm thấy sản phẩm phù hợp.",
                              style: TextStyle(color: AppTheme.textSecondaryColor),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: productProvider.filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = productProvider.filteredProducts[index];
                              final isPromo = product.promoPrice != null;
                              final dispPrice = product.promoPrice ?? product.price;

                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailScreen(product: product),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image
                                      Expanded(
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              product.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => const Center(
                                                child: Icon(Icons.broken_image_outlined, size: 40),
                                              ),
                                            ),
                                            if (isPromo)
                                              Positioned(
                                                top: 10,
                                                left: 10,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    "GIẢM",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (product.stock <= 0)
                                              Container(
                                                color: Colors.black.withOpacity(0.4),
                                                child: const Center(
                                                  child: Text(
                                                    "Hết hàng",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Info
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: textTheme.titleMedium?.copyWith(
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              product.flowerType,
                                              style: textTheme.bodyMedium?.copyWith(
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(
                                                  formatVnd(dispPrice),
                                                  style: textTheme.labelLarge?.copyWith(
                                                    fontSize: 15,
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                ),
                                                if (isPromo) ...[
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    formatVnd(product.price),
                                                    style: const TextStyle(
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}

// Bottom sheet containing filter items
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String? _selectedColor;
  bool _onlyInStock = false;
  bool _onlyPromo = false;

  @override
  void initState() {
    super.initState();
    final pProv = Provider.of<ProductProvider>(context, listen: false);
    _minPriceController.text = pProv.minPrice?.toString() ?? '';
    _maxPriceController.text = pProv.maxPrice?.toString() ?? '';
    _selectedColor = pProv.selectedColor;
    _onlyInStock = pProv.onlyInStock;
    _onlyPromo = pProv.onlyPromo;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pProv = Provider.of<ProductProvider>(context);
    final colorsList = pProv.availableColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Bộ lọc", style: textTheme.titleLarge),
              TextButton(
                onPressed: () {
                  pProv.clearFilters();
                  Navigator.pop(context);
                },
                child: const Text("Đặt lại", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),

          // Price range fields
          Text("Khoảng giá", style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Giá thấp nhất (VND)",
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Giá cao nhất (VND)",
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Color selection
          Text("Màu hoa", style: textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedColor,
            hint: const Text("Chọn màu"),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text("Tất cả màu"),
              ),
              ...colorsList.map((color) => DropdownMenuItem<String>(
                    value: color,
                    child: Text(color),
                  )),
            ],
            onChanged: (val) {
              setState(() {
                _selectedColor = val;
              });
            },
          ),
          const SizedBox(height: 16),

          // Toggle Switches
          SwitchListTile(
            title: const Text("Chỉ sản phẩm còn hàng"),
            activeThumbColor: AppTheme.primaryColor,
            value: _onlyInStock,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _onlyInStock = val;
              });
            },
          ),
          SwitchListTile(
            title: const Text("Sản phẩm đang giảm giá"),
            activeThumbColor: AppTheme.primaryColor,
            value: _onlyPromo,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _onlyPromo = val;
              });
            },
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              final min = double.tryParse(_minPriceController.text);
              final max = double.tryParse(_maxPriceController.text);
              pProv.setFilters(
                minPrice: min,
                maxPrice: max,
                color: _selectedColor,
                onlyInStock: _onlyInStock,
                onlyPromo: _onlyPromo,
              );
              Navigator.pop(context);
            },
            child: const Text("Áp dụng"),
          ),
        ],
      ),
    );
  }
}
