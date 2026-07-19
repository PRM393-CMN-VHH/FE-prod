import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prm393/features/catalog/models/product.dart';
import 'package:prm393/features/cart/models/cart_item.dart';
import 'package:prm393/core/network/api_client_base.dart';

/// Shopping cart.
mixin CartApi on ApiClientBase {
  static const String _keyCart = 'api_cart';

  Future<List<CartItem>> getCartItems(List<Product> products) async {
    final response = await request(ApiEndpoints.cart);
    if (response is Map && response.containsKey('cart')) {
      final List<dynamic> list = response['cart'] as List<dynamic>;
      final List<CartItem> items = [];
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final product = Product.fromJson(
          map['product'] as Map<String, dynamic>,
        );
        items.add(
          CartItem(
            id: product.id,
            cartItemId: map['cartItemId'] is int
                ? map['cartItemId'] as int
                : int.tryParse(map['cartItemId']?.toString() ?? ''),
            product: product,
            quantity: map['quantity'] is int
                ? map['quantity'] as int
                : int.parse(map['quantity'].toString()),
          ),
        );
      }
      return items;
    }
    throw Exception("Invalid cart response from server");
  }

  Future<void> addToCart(int productId, int quantity) async {
    try {
      await request(
        ApiEndpoints.cartAdd,
        body: {"productId": productId, "quantity": quantity},
      );
    } catch (e) {
      throw Exception(friendlyRequestError(e));
    }
  }

  Future<void> updateCart(int productId, int quantity) async {
    try {
      await request(
        ApiEndpoints.cartUpdate,
        body: {"productId": productId, "quantity": quantity},
      );
    } catch (e) {
      throw Exception(friendlyRequestError(e));
    }
  }

  Future<void> removeFromCart(int productId) async {
    try {
      await request(ApiEndpoints.cartRemove, body: {"productId": productId});
    } catch (e) {
      throw Exception(friendlyRequestError(e));
    }
  }

  Future<void> saveCartItems(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = items.map((item) => item.toJson()).toList();
    await prefs.setString(_keyCart, jsonEncode(listJson));
  }

  Future<Map<String, dynamic>> getCheckoutSummary() async {
    final response = await request(ApiEndpoints.cartCheckout);
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw Exception("Invalid checkout response from server");
  }
}
