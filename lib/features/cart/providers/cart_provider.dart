import 'package:flutter/material.dart';
import 'package:prm393/features/cart/models/cart_item.dart';
import 'package:prm393/features/catalog/models/product.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/utils/error_translator.dart';

class CartProvider extends ChangeNotifier {
  // Flat shipping fee, waived for orders at/above the free-shipping threshold.
  // Keep in sync with CartController.SHIPPING_FEE / FREE_SHIPPING_THRESHOLD
  // on the backend, which is the source of truth for the amount actually charged.
  static const double shippingFeeFlat = 30000;
  static const double freeShippingThreshold = 500000;

  final ApiService _apiService = ApiService();

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<int, int> _optimisticQuantities = {};

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalItemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get subtotalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get shippingFee {
    if (_items.isEmpty) return 0.0;
    return subtotalAmount >= freeShippingThreshold ? 0.0 : shippingFeeFlat;
  }

  double get totalAmount => subtotalAmount + shippingFee;

  // How much more the customer needs to add to qualify for free shipping (0 if already free).
  double get amountToFreeShipping {
    if (_items.isEmpty || subtotalAmount >= freeShippingThreshold) return 0.0;
    return freeShippingThreshold - subtotalAmount;
  }

  Future<void> loadCart(List<Product> products) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _apiService.getCartItems(products);
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addToCart(Product product, int quantity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.addToCart(product.id, quantity);
      _items = await _apiService.getCartItems([product]);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuantity(int cartItemId, int newQuantity) async {
    _errorMessage = null;

    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index == -1) return false;

    final item = _items[index];
    final oldQuantity = item.quantity;

    // Optimistic update: change local quantity and notify immediately
    item.quantity = newQuantity;
    _optimisticQuantities[cartItemId] = newQuantity;
    notifyListeners();

    try {
      await _apiService.updateCart(cartItemId, newQuantity);
      
      // Fetch fresh items from the API to stay synchronized
      final freshItems = await _apiService.getCartItems([]);

      // Clear the tracking if no newer update has occurred for this item
      if (_optimisticQuantities[cartItemId] == newQuantity) {
        _optimisticQuantities.remove(cartItemId);
      }

      // Re-apply any other active optimistic quantities to the fresh list
      for (final fresh in freshItems) {
        if (_optimisticQuantities.containsKey(fresh.id)) {
          fresh.quantity = _optimisticQuantities[fresh.id]!;
        }
      }

      _items = freshItems;
      notifyListeners();
      return true;
    } catch (e) {
      _optimisticQuantities.remove(cartItemId);
      // Rollback on failure
      item.quantity = oldQuantity;
      _errorMessage = ErrorTranslator.userMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFromCart(int cartItemId) async {
    _errorMessage = null;

    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index == -1) return false;

    final removedItem = _items[index];

    // Optimistic remove: remove locally and notify immediately
    _items.removeAt(index);
    notifyListeners();

    try {
      await _apiService.removeFromCart(cartItemId);
      _items = await _apiService.getCartItems([]);
      notifyListeners();
      return true;
    } catch (e) {
      // Rollback on failure
      _items.insert(index, removedItem);
      _errorMessage = ErrorTranslator.userMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    await _apiService.saveCartItems(_items);
  }
}
