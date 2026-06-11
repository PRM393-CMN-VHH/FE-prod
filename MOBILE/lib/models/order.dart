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

  factory OrderItem.fromJson(
    Map<String, dynamic> json, [
    Product? fallbackProduct,
  ]) {
    final int itemDetailId = json['orderDetailId'] ?? json['id'] ?? 0;
    Product prod;
    if (json['product'] != null && json['product'] is Map) {
      prod = Product.fromJson(json['product'] as Map<String, dynamic>);
    } else if (fallbackProduct != null) {
      prod = fallbackProduct;
    } else {
      throw Exception("Product data is missing in OrderItem payload");
    }
    return OrderItem(
      id: itemDetailId,
      product: prod,
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.parse((json['quantity'] ?? 0).toString()),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
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
  final String paymentStatus;
  final String? paymentUrl;
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
    this.paymentStatus = '',
    this.paymentUrl,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(
    Map<String, dynamic> json,
    List<OrderItem> items,
  ) {
    final int orderId = json['orderId'] ?? json['id'] ?? 0;
    final double amt =
        (json['totalPrice'] as num? ?? json['total_amount'] as num? ?? 0)
            .toDouble();

    // Fallback recipient from user object
    String name = json['recipient_name'] ?? '';
    String phone = json['recipient_phone'] ?? '';
    String addr = json['shipping_address'] ?? '';

    if (json['user'] != null && json['user'] is Map) {
      final userMap = json['user'] as Map<String, dynamic>;
      if (name.isEmpty) name = userMap['fullName'] ?? '';
      if (phone.isEmpty) phone = userMap['phoneNumber'] ?? '';
      if (addr.isEmpty) addr = userMap['address'] ?? '';
    }

    final String pMethod =
        json['paymentMethod'] ?? json['payment_method'] ?? 'COD';
    final String ordStatus = json['orderStatus'] ?? json['status'] ?? 'Pending';
    final String payStatus =
        json['paymentStatus'] ?? json['payment_status'] ?? '';
    final String? paymentUrl = json['paymentUrl'] ?? json['payment_url'];

    DateTime cAt = DateTime.now();
    try {
      if (json['createdAt'] != null) {
        cAt = DateTime.parse(json['createdAt'] as String);
      } else if (json['created_at'] != null) {
        cAt = DateTime.parse(json['created_at'] as String);
      }
    } catch (_) {}

    return OrderModel(
      id: orderId,
      totalAmount: amt,
      recipientName: name,
      recipientPhone: phone,
      shippingAddress: addr,
      paymentMethod: pMethod,
      status: ordStatus,
      paymentStatus: payStatus,
      paymentUrl: paymentUrl,
      createdAt: cAt,
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
      'payment_status': paymentStatus,
      'payment_url': paymentUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
