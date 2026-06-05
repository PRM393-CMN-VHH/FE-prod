import 'package:flutter/material.dart';
import 'package:prm393/models/cart_item.dart';
import 'package:prm393/models/product.dart';
import 'package:prm393/services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;

  int get totalItemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get subtotalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get shippingFee {
    if (_items.isEmpty) return 0.0;
    // Free delivery for orders over 100
    return subtotalAmount >= 100.0 ? 0.0 : 5.0;
  }

  double get totalAmount => subtotalAmount + shippingFee;

  Future<void> loadCart(List<Product> products) async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _apiService.getCartItems(products);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addToCart(Product product, int quantity) async {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      final newId = DateTime.now().millisecondsSinceEpoch + product.id;
      _items.add(CartItem(
        id: newId,
        product: product,
        quantity: quantity,
      ));
    }
    notifyListeners();
    await _apiService.saveCartItems(_items);
  }

  Future<void> updateQuantity(int cartItemId, int newQuantity) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      notifyListeners();
      await _apiService.saveCartItems(_items);
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    _items.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
    await _apiService.saveCartItems(_items);
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    await _apiService.saveCartItems(_items);
  }
}
