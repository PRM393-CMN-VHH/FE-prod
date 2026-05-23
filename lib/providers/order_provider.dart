import 'package:flutter/material.dart';
import 'package:prm393/models/cart_item.dart';
import 'package:prm393/models/order.dart';
import 'package:prm393/models/product.dart';
import 'package:prm393/services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadOrders(List<Product> products) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _apiService.getOrders(products);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> getVnpayUrl({required double amount, required String orderId}) async {
    try {
      return await _apiService.createVnpayPaymentUrl(amount: amount, orderId: orderId);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
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
      
      _orders.insert(0, order);
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
