import 'package:flutter/material.dart';
import 'package:prm393/features/cart/models/cart_item.dart';
import 'package:prm393/features/orders/models/order.dart';
import 'package:prm393/features/catalog/models/product.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/utils/error_translator.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Cached per status filter (key 'ALL' = no filter / null), so switching
  // between status tabs doesn't clobber another tab's already-loaded list.
  final Map<String, List<OrderModel>> _ordersByStatus = {};
  final Set<String> _loadingStatuses = {};
  bool _isLoading = false;
  String? _errorMessage;

  static String _key(String? status) => status ?? 'ALL';

  List<OrderModel> ordersFor(String? status) =>
      _ordersByStatus[_key(status)] ?? [];
  bool isLoadingStatus(String? status) =>
      _loadingStatuses.contains(_key(status));

  // Back-compat accessor for callers that only care about the unfiltered list.
  List<OrderModel> get orders => ordersFor(null);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadOrders(List<Product> products, {String? status}) async {
    final key = _key(status);
    _loadingStatuses.add(key);
    _errorMessage = null;
    notifyListeners();

    try {
      _ordersByStatus[key] = await _apiService.getOrders(
        products,
        status: status,
      );
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
    }

    _loadingStatuses.remove(key);
    notifyListeners();
  }

  Future<String?> getVnpayUrl({
    required double amount,
    required String orderId,
  }) async {
    try {
      return await _apiService.createVnpayPaymentUrl(
        amount: amount,
        orderId: orderId,
      );
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
      return null;
    }
  }

  Future<String?> repayOrder(int orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final paymentUrl = await _apiService.repayOrder(orderId);
      _isLoading = false;
      notifyListeners();
      return paymentUrl;
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Cancelling can move an order in/out of any status tab's cached list, so
  // drop the whole cache and just refresh the tab the user is currently on.
  Future<bool> cancelOrder(
    int orderId,
    List<Product> products, {
    String? currentStatus,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.cancelOrder(orderId);
      _ordersByStatus.clear();
      _isLoading = false;
      notifyListeners();
      await loadOrders(products, status: currentStatus);
      return true;
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Same cache-invalidation approach as cancelOrder: confirming receipt moves
  // the order from DELIVERED to COMPLETED, affecting two tabs' caches.
  Future<bool> confirmReceived(
    int orderId,
    List<Product> products, {
    String? currentStatus,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.confirmOrderReceived(orderId);
      _ordersByStatus.clear();
      _isLoading = false;
      notifyListeners();
      await loadOrders(products, status: currentStatus);
      return true;
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<OrderModel?> placeOrder({
    required String recipientName,
    required String recipientPhone,
    required String shippingAddress,
    required String paymentMethod,
    required double totalAmount,
    required List<CartItem> cartItems,
    String status = "Confirmed",
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _apiService.createOrder(
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        totalAmount: totalAmount,
        cartItems: cartItems,
        status: status,
      );

      // A newly placed order invalidates any cached status lists.
      _ordersByStatus.clear();
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
