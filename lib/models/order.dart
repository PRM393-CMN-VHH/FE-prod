import 'package:prm393/models/product.dart';

class OrderItem {
  final int id;
  final Product product;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json, Product product) {
    return OrderItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      product: product,
      quantity: json['quantity'] is int ? json['quantity'] : int.parse(json['quantity'].toString()),
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': product.id,
      'quantity': quantity,
      'price': price,
    };
  }
}

class OrderModel {
  final int id;
  final double totalAmount;
  final String recipientName;
  final String recipientPhone;
  final String shippingAddress;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.totalAmount,
    required this.recipientName,
    required this.recipientPhone,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, List<OrderItem> items) {
    return OrderModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      totalAmount: (json['total_amount'] as num).toDouble(),
      recipientName: json['recipient_name'] as String? ?? '',
      recipientPhone: json['recipient_phone'] as String? ?? '',
      shippingAddress: json['shipping_address'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'COD',
      status: json['status'] as String? ?? 'Pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
