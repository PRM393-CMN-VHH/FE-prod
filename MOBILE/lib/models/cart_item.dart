import 'package:prm393/models/product.dart';

class CartItem {
  final int id;
  final int? cartItemId;
  final Product product;
  int quantity;

  CartItem({
    required this.id,
    this.cartItemId,
    required this.product,
    required this.quantity,
  });

  double get totalPrice => (product.promoPrice ?? product.price) * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json, Product product) {
    return CartItem(
      id: json['productId'] is int
          ? json['productId'] as int
          : json['product_id'] is int
              ? json['product_id'] as int
              : product.id,
      cartItemId: json['cartItemId'] is int
          ? json['cartItemId'] as int
          : int.tryParse(json['cartItemId']?.toString() ?? ''),
      product: product,
      quantity: json['quantity'] is int ? json['quantity'] : int.parse(json['quantity'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart_item_id': cartItemId,
      'product_id': product.id,
      'quantity': quantity,
    };
  }
}
