import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/catalog/providers/product_provider.dart';

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
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
                child: const Text(
                  "Đặt lại",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),
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
              ...colorsList.map(
                (color) =>
                    DropdownMenuItem<String>(value: color, child: Text(color)),
              ),
            ],
            onChanged: (val) {
              setState(() {
                _selectedColor = val;
              });
            },
          ),
          const SizedBox(height: 16),
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
