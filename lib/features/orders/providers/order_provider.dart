import 'dart:async';
import 'package:flutter/material.dart';
import 'package:prm393/features/cart/models/cart_item.dart';
import 'package:prm393/features/orders/models/order.dart';
import 'package:prm393/features/catalog/models/product.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/network/order_socket_service.dart';
import 'package:prm393/core/utils/error_translator.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final OrderSocketService _socket = OrderSocketService.instance;
  StreamSubscription<OrderSocketEvent>? _socketSubscription;

  // Cached per status filter (key 'ALL' = no filter / null), so switching
  // between status tabs doesn't clobber another tab's already-loaded list.
  final Map<String, List<OrderModel>> _ordersByStatus = {};
  // Remembers the args each status was last loaded with, so a live socket
  // event can silently re-fetch that same tab without the screen asking again.
  final Map<String, List<Product>> _lastLoadArgs = {};
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
    _lastLoadArgs[key] = products;
    _loadingStatuses.add(key);
    _errorMessage = null;
    notifyListeners();

    try {
      _ordersByStatus[key] = await _apiService.getOrders(
        products,
        status: status,
      );
      unawaited(_connectSocket());
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
    }

    _loadingStatuses.remove(key);
    notifyListeners();
  }

  // Connects once and keeps listening for the provider's whole lifetime; a new
  // order or a status change pushed by the backend silently re-fetches whatever
  // status tabs are currently cached, so the on-screen list updates itself.
  Future<void> _connectSocket() async {
    final cookie = await _apiService.getSessionCookie();
    await _socket.connect(wsUrl: ApiService.wsOrdersUrl, cookie: cookie);
    _socketSubscription ??= _socket.events?.listen(_handleSocketEvent);
  }

  void _handleSocketEvent(OrderSocketEvent event) {
    if (event.type != 'order_status_changed' && event.type != 'order_updated') {
      return;
    }
    for (final key in _ordersByStatus.keys.toList()) {
      final products = _lastLoadArgs[key];
      if (products == null) continue;
      unawaited(loadOrders(products, status: key == 'ALL' ? null : key));
    }
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

  @override
  void dispose() {
    // Don't disconnect: OrderSocketService.instance is shared with other
    // providers/widgets that may still be listening.
    _socketSubscription?.cancel();
    super.dispose();
  }
}
