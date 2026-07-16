import 'package:flutter/material.dart';
import 'package:prm393/features/cart/models/cart_item.dart';
import 'package:prm393/features/orders/models/order.dart';
import 'package:prm393/features/catalog/models/product.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/utils/error_translator.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<OrderModel> _orders = [];
  List<OrderModel> _paidTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  List<OrderModel> get paidTransactions => _paidTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadOrders(List<Product> products) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _apiService.getOrders(products);
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
    }

    _isLoading = false;
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

  Future<bool> cancelOrder(int orderId, List<Product> products) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.cancelOrder(orderId);
      _orders = await _apiService.getOrders(products);
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

  Future<void> loadTransactionHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _paidTransactions = await _apiService.getTransactionHistory();
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
    }
    _isLoading = false;
    notifyListeners();
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

      _orders.insert(0, order);
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
