import 'package:flutter/material.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/features/catalog/models/category.dart';
import 'package:prm393/features/catalog/models/product.dart';

class ProductEditorDialog extends StatefulWidget {
  final Product? product;

  const ProductEditorDialog({super.key, this.product});

  @override
  State<ProductEditorDialog> createState() => ProductEditorDialogState();
}

class ProductEditorDialogState extends State<ProductEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _categoryId = 1;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.price.toStringAsFixed(0);
      _stockController.text = product.stock.toString();
      _imageController.text = product.imageUrl;
      _descriptionController.text = product.description;
      _categoryId = product.categoryId == 0 ? 1 : product.categoryId;
    }
    ApiService().getCategories().then((value) {
      if (!mounted) return;
      setState(() {
        _categories = value;
        if (_categories.isNotEmpty &&
            !_categories.any((category) => category.id == _categoryId)) {
          _categoryId = _categories.first.id;
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final old = widget.product;
    Navigator.pop(
      context,
      Product(
        id: old?.id ?? 0,
        name: _nameController.text.trim(),
        categoryId: _categoryId,
        imageUrl: _imageController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text.trim(),
        careInstructions: old?.careInstructions ?? '',
        stock: int.parse(_stockController.text.trim()),
        isAvailable: true,
        flowerType: old?.flowerType ?? '',
        color: old?.color ?? '',
        size: old?.size ?? '',
        freshness: old?.freshness ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? "Thêm sản phẩm" : "Sửa sản phẩm"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Tên"),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? "Bắt buộc" : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Giá"),
                keyboardType: TextInputType.number,
                validator: (value) => double.tryParse(value ?? '') == null
                    ? "Giá không hợp lệ"
                    : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: "Tồn kho"),
                keyboardType: TextInputType.number,
                validator: (value) => int.tryParse(value ?? '') == null
                    ? "Số không hợp lệ"
                    : null,
              ),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: "Ảnh URL"),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Mô tả"),
                maxLines: 2,
              ),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: "Danh mục"),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _categoryId = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
        ElevatedButton(onPressed: _submit, child: const Text("Lưu")),
      ],
    );
  }
}
