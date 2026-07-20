import 'package:flutter/material.dart';
import 'package:prm393/core/constants/app_messages.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/catalog/models/category.dart';
import 'package:prm393/features/catalog/models/product.dart';

class ProductEditorScreen extends StatefulWidget {
  final Product? product;

  const ProductEditorScreen({super.key, this.product});

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _promoPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _categoryId = 1;
  List<Category> _categories = [];
  String _imageUrl = "";

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.price.toStringAsFixed(0);
      _promoPriceController.text =
          product.promoPrice?.toStringAsFixed(0) ?? '';
      _stockController.text = product.stock.toString();
      _imageController.text = product.imageUrl;
      _descriptionController.text = product.description;
      _categoryId = product.categoryId == 0 ? 1 : product.categoryId;
    }
    _imageUrl = _imageController.text.trim();
    _imageController.addListener(_onImageUrlChanged);

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

  void _onImageUrlChanged() {
    setState(() {
      _imageUrl = _imageController.text.trim();
    });
  }

  @override
  void dispose() {
    _imageController.removeListener(_onImageUrlChanged);
    _nameController.dispose();
    _priceController.dispose();
    _promoPriceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final old = widget.product;
    final promoText = _promoPriceController.text.trim();
    Navigator.pop(
      context,
      Product(
        id: old?.id ?? 0,
        name: _nameController.text.trim(),
        categoryId: _categoryId,
        imageUrl: _imageController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        promoPrice: promoText.isEmpty ? null : double.parse(promoText),
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.product == null ? "Thêm sản phẩm" : "Sửa sản phẩm",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Preview Container at the top
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _imageUrl.isNotEmpty
                          ? Image.network(
                              _imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImagePlaceholder(
                                      icon: Icons.broken_image_outlined,
                                      text: "Lỗi tải hình ảnh"),
                            )
                          : _buildImagePlaceholder(
                              icon: Icons.image_outlined,
                              text: "Chưa có hình ảnh sản phẩm"),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Form Fields with labels on top
                _buildFieldLabel("Tên sản phẩm"),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: "Nhập tên sản phẩm",
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? AppMessage.fieldRequired.text
                      : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel("Giá (đ)"),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    hintText: "Nhập giá bán",
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => double.tryParse(value ?? '') == null
                      ? AppMessage.priceInvalid.text
                      : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel("Giá khuyến mãi (đ, bỏ trống nếu không)"),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _promoPriceController,
                  decoration: const InputDecoration(
                    hintText: "Nhập giá khuyến mãi",
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    final promo = double.tryParse(text);
                    if (promo == null) return AppMessage.priceInvalid.text;
                    final price = double.tryParse(_priceController.text.trim());
                    if (price != null && promo >= price) {
                      return AppMessage.promoMustBeLower.text;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildFieldLabel("Số lượng tồn kho"),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    hintText: "Nhập số lượng tồn kho",
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => int.tryParse(value ?? '') == null
                      ? AppMessage.numberInvalid.text
                      : null,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel("Đường dẫn hình ảnh (URL)"),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(
                    hintText: "Nhập link ảnh sản phẩm",
                  ),
                ),
                const SizedBox(height: 16),

                _buildFieldLabel("Mô tả sản phẩm"),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: "Nhập mô tả sản phẩm",
                  ),
                  maxLines: 6,
                ),
                const SizedBox(height: 16),

                _buildFieldLabel("Danh mục sản phẩm"),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: _categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                  decoration: const InputDecoration(
                    hintText: "Chọn danh mục",
                  ),
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
                  validator: (value) => value == null ? "Vui lòng chọn danh mục" : null,
                ),
                const SizedBox(height: 32),
                
                // Bottom actions row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          AppMessage.cancelAction.text,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text(
                          "Lưu",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildImagePlaceholder({required IconData icon, required String text}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
