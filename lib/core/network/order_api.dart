import 'package:prm393/features/catalog/models/product.dart';
import 'package:prm393/features/cart/models/cart_item.dart';
import 'package:prm393/features/orders/models/order.dart';
import 'package:prm393/core/network/api_client_base.dart';

/// Orders, order history, and VNPay payment.
mixin OrderApi on ApiClientBase {
  Future<List<OrderModel>> getOrders(List<Product> products) async {
    final response = await request(ApiEndpoints.orders);
    if (response is List) {
      final List<OrderModel> orders = [];
      for (final oMap in response) {
        final map = oMap as Map<String, dynamic>;
        final List<OrderItem> orderItems = [];
        if (map.containsKey('orderDetails') && map['orderDetails'] is List) {
          final detailsList = map['orderDetails'] as List<dynamic>;
          for (final detail in detailsList) {
            orderItems.add(OrderItem.fromJson(detail as Map<String, dynamic>));
          }
        }
        orders.add(OrderModel.fromJson(map, orderItems));
      }
      return orders.reversed.toList();
    }
    throw Exception("Invalid orders response from server");
  }

  Future<OrderModel> getOrderDetail(int orderId) async {
    final response = await request(
      ApiEndpoints.orderDetail,
      params: {'orderId': orderId},
    );
    if (response is Map &&
        response['order'] is Map &&
        response['orderDetails'] is List) {
      final items = (response['orderDetails'] as List)
          .map((json) => OrderItem.fromJson(json as Map<String, dynamic>))
          .toList();
      return OrderModel.fromJson(
        response['order'] as Map<String, dynamic>,
        items,
      );
    }
    throw Exception("Invalid order detail response from server");
  }

  Future<String> repayOrder(int orderId) async {
    final response = await request(
      ApiEndpoints.orderPay,
      params: {'orderId': orderId},
    );
    if (response is Map && response['redirectUrl'] is String) {
      final redirectUrl = response['redirectUrl'] as String;
      final paymentResponse = await getRequest(backendUrl(redirectUrl));
      if (paymentResponse is Map && paymentResponse['paymentUrl'] is String) {
        return paymentResponse['paymentUrl'] as String;
      }
    }
    throw Exception("Invalid repay response from server");
  }

  Future<void> cancelOrder(int orderId) async {
    await request(ApiEndpoints.orderCancel, params: {'orderId': orderId});
  }

  Future<List<OrderModel>> getTransactionHistory() async {
    final response = await request(ApiEndpoints.transactionHistory);
    if (response is List) {
      return response
          .map(
            (json) {
              final map = json as Map<String, dynamic>;
              final List<OrderItem> orderItems = [];
              if (map.containsKey('orderDetails') && map['orderDetails'] is List) {
                final detailsList = map['orderDetails'] as List<dynamic>;
                for (final detail in detailsList) {
                  orderItems.add(OrderItem.fromJson(detail as Map<String, dynamic>));
                }
              }
              return OrderModel.fromJson(map, orderItems);
            },
          )
          .toList()
          .reversed
          .toList();
    }
    throw Exception("Invalid transaction history response from server");
  }

  // ==========================================
  // VNPAY PAYMENT
  // ==========================================

  Future<String> createVnpayPaymentUrl({
    required double amount,
    required String orderId,
    String ipAddress = '127.0.0.1',
  }) async {
    final response = await request(
      ApiEndpoints.paymentCreate,
      query: {'orderId': orderId, 'amount': amount.toInt().toString()},
    );
    if (response is Map && response['paymentUrl'] is String) {
      return response['paymentUrl'] as String;
    }
    throw Exception("Không thể tạo liên kết thanh toán VNPay từ máy chủ");
  }

  Future<OrderModel> createOrder({
    required String recipientName,
    required String recipientPhone,
    required String shippingAddress,
    required String paymentMethod,
    required double totalAmount,
    required List<CartItem> cartItems,
    String status = "Confirmed",
  }) async {
    // Place the order — the backend links the order to the current session user.
    // paymentMethod expected by backend: "COD" or "VNPay"
    final response = await request(
      ApiEndpoints.placeOrder,
      body: {"paymentMethod": paymentMethod == "VNPAY" ? "VNPay" : "COD"},
    );

    if (response is! Map || response['order'] is! Map) {
      throw Exception("Invalid place order response from server");
    }

    String? paymentUrl;
    if (paymentMethod == "VNPAY") {
      if (response['paymentUrl'] is String) {
        paymentUrl = response['paymentUrl'] as String;
      } else if (response['redirectUrl'] is String) {
        final paymentResponse = await getRequest(
          backendUrl(response['redirectUrl'] as String),
        );
        if (paymentResponse is Map && paymentResponse['paymentUrl'] is String) {
          paymentUrl = paymentResponse['paymentUrl'] as String;
        }
      }

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception("Không thể tạo liên kết thanh toán VNPay từ máy chủ");
      }
    }

    final orderItems = cartItems
        .map(
          (c) => OrderItem(
            id: c.product.id,
            product: c.product,
            quantity: c.quantity,
            price: c.product.promoPrice ?? c.product.price,
          ),
        )
        .toList();

    final orderPayload = Map<String, dynamic>.from(
      response['order'] as Map<String, dynamic>,
    );
    if (paymentUrl != null) {
      orderPayload['paymentUrl'] = paymentUrl;
    }

    // Thông báo "Đặt hàng thành công" do backend tạo khi xử lý place-order
    return OrderModel.fromJson(orderPayload, orderItems);
  }
}
