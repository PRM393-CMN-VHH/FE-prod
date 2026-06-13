import 'package:flutter/material.dart';
import 'package:prm393/models/category.dart';
import 'package:prm393/models/product.dart';
import 'package:prm393/services/api_service.dart';
import 'package:prm393/utils/error_translator.dart';
import 'package:prm393/utils/flower_color_formatter.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  List<Product> _catalogProducts = [];
  List<Category> _categories = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter criteria
  int _selectedCategoryId = 0; // 0 means 'All'
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  String? _selectedColor;
  bool _onlyInStock = false;
  bool _onlyPromo = false;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Map<String, dynamic>> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  String? get selectedColor => _selectedColor;
  bool get onlyInStock => _onlyInStock;
  bool get onlyPromo => _onlyPromo;

  ProductProvider() {
    loadCatalog();
  }

  Future<void> loadCatalog() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _apiService.getCategories();
      _products = await _apiService.getProducts();
      _catalogProducts = List<Product>.from(_products);
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectCategory(int categoryId) async {
    _selectedCategoryId = categoryId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _products = categoryId == 0
          ? await _apiService.getProducts()
          : await _apiService.getProductsByCategory(categoryId);
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (query.trim().isEmpty) {
        _suggestions = [];
        _products = _selectedCategoryId == 0
            ? await _apiService.getProducts()
            : await _apiService.getProductsByCategory(_selectedCategoryId);
      } else {
        _products = await _apiService.searchProducts(query.trim());
        _suggestions = await _apiService.suggestProducts(query.trim());
      }
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Product> loadProductDetail(int productId) {
    return _apiService.getProductDetail(productId);
  }

  Future<List<Product>> loadRelatedProducts(int productId) {
    return _apiService.getRelatedProducts(productId);
  }

  void setFilters({
    double? minPrice,
    double? maxPrice,
    String? color,
    bool onlyInStock = false,
    bool onlyPromo = false,
  }) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _selectedColor = color;
    _onlyInStock = onlyInStock;
    _onlyPromo = onlyPromo;
    notifyListeners();
  }

  void clearFilters() {
    _minPrice = null;
    _maxPrice = null;
    _selectedColor = null;
    _onlyInStock = false;
    _onlyPromo = false;
    _searchQuery = '';
    _selectedCategoryId = 0;
    _suggestions = [];
    notifyListeners();
    loadCatalog();
  }

  // Get filtered products list dynamically
  List<Product> get filteredProducts {
    return _products.where((product) {
      // 1. Category Filter
      if (_selectedCategoryId != 0 &&
          product.categoryId != _selectedCategoryId) {
        return false;
      }

      // 2. Search Query Filter
      if (_searchQuery.isNotEmpty &&
          !product.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !product.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          )) {
        return false;
      }

      // 3. Price Filter
      final currentPrice = product.hasDiscount
          ? product.promoPrice!
          : product.price;
      if (_minPrice != null && currentPrice < _minPrice!) {
        return false;
      }
      if (_maxPrice != null && currentPrice > _maxPrice!) {
        return false;
      }

      // 4. Color Filter
      if (_selectedColor != null &&
          _selectedColor!.isNotEmpty &&
          flowerColorKey(product.color) != flowerColorKey(_selectedColor!)) {
        return false;
      }

      // 5. Stock Filter
      if (_onlyInStock && product.stock <= 0) {
        return false;
      }

      // 6. Promo Filter
      if (_onlyPromo && !product.hasDiscount) {
        return false;
      }

      return true;
    }).toList();
  }

  // List of unique colors available in current products
  List<String> get availableColors {
    final source = _catalogProducts.isNotEmpty ? _catalogProducts : _products;
    final colors = source
        .map((p) => flowerColorLabel(p.color))
        .where((color) => color.isNotEmpty)
        .toSet()
        .toList();
    colors.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return colors;
  }
}
