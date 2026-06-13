import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prm393/models/category.dart';
import 'package:prm393/models/product.dart';
import 'package:prm393/models/user.dart';
import 'package:prm393/models/cart_item.dart';
import 'package:prm393/models/order.dart';
import 'package:prm393/models/notification.dart';
import 'package:prm393/models/message.dart';
import 'package:prm393/models/store_location.dart';
import 'package:prm393/utils/error_translator.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const Duration _requestTimeout = Duration(seconds: 15);

  // ==========================================
  // API URL CONSTANTS & CONFIGURATIONS
  // ==========================================

  static String get backendBaseUrl {
    if (kIsWeb) {
      return "http://localhost:3636";
    }
    // For Android emulator, use 10.0.2.2 to access host's localhost.
    // For iOS simulator or real devices, localhost or local IP is used.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:3636";
    }
    return "http://localhost:3636";
  }

  // Auth Routes
  static String get apiSignIn => "$backendBaseUrl/login";
  static String get apiSignUp => "$backendBaseUrl/register";
  static String get apiRequestOtp => "$backendBaseUrl/register/request-otp";
  static String get apiSignOut => "$backendBaseUrl/logout";
  static String get apiCurrentUser => "$backendBaseUrl/api/users/me";
  static String get apiProfile => "$backendBaseUrl/profile";
  static String get apiProfileUpdate => "$backendBaseUrl/profile/update";

  // Catalog & Shopping Routes
  static String get apiProducts => "$backendBaseUrl/product/all-product";
  static String get apiCategoryProducts => "$backendBaseUrl/product/category";
  static String get apiProductDetails => "$backendBaseUrl/products";
  static String get apiProductSuggest => "$backendBaseUrl/api/products/suggest";
  static String get apiAdminCategories =>
      "$backendBaseUrl/admin/product/categories";

  // Cart Routes
  static String get apiCart => "$backendBaseUrl/cart";
  static String get apiCartAdd => "$backendBaseUrl/cart/add";
  static String get apiCartUpdate => "$backendBaseUrl/cart/update";
  static String get apiCartRemove => "$backendBaseUrl/cart/remove";
  static String get apiCartCheckout => "$backendBaseUrl/cart/checkout";
  static String get apiPlaceOrder => "$backendBaseUrl/cart/place-order";

  // Orders & Payments Routes
  static String get apiOrders => "$backendBaseUrl/order/my-orders";
  static String get apiOrderDetail => "$backendBaseUrl/order/detail";
  static String get apiOrderPay => "$backendBaseUrl/order/pay";
  static String get apiOrderCancel => "$backendBaseUrl/order/cancel";
  static String get apiTransactionHistory =>
      "$backendBaseUrl/transaction/history";
  static String get apiPaymentCreate => "$backendBaseUrl/payment/create";

  // Admin Routes
  static String get apiAdminLogin => "$backendBaseUrl/admin/login";
  static String get apiAdminDashboard => "$backendBaseUrl/admin/dashboard";
  static String get apiAdminOrders => "$backendBaseUrl/admin/orders";
  static String get apiAdminOrderUpdateStatus =>
      "$backendBaseUrl/admin/orders/update-status";
  static String get apiAdminProducts => "$backendBaseUrl/admin/products";
  static String get apiAdminProductAdd => "$backendBaseUrl/admin/products/add";
  static String get apiAdminProductEdit =>
      "$backendBaseUrl/admin/products/edit";
  static String get apiAdminProductDelete =>
      "$backendBaseUrl/admin/products/delete";
  static String get apiAdminProductCombo =>
      "$backendBaseUrl/admin/products/combo";
  static String get apiAdminProductComboAddItem =>
      "$backendBaseUrl/admin/products/combo/add-item";
  static String get apiAdminProductComboRemoveItem =>
      "$backendBaseUrl/admin/products/combo/remove-item";
  static String get apiAdminUsers => "$backendBaseUrl/admin/users";
  static String get apiAdminUserActivate =>
      "$backendBaseUrl/admin/users/activate";
  static String get apiAdminUserDeactivate =>
      "$backendBaseUrl/admin/users/deactivate";
  static String get apiAdminUserUpdateRole =>
      "$backendBaseUrl/admin/users/update-role";

  SupabaseClient? _supabase;
  bool get isSupabaseInitialized => _supabase != null;

  String? _sessionCookie;

  String _backendUrl(String pathOrUrl) {
    final uri = Uri.tryParse(pathOrUrl);
    if (uri != null && uri.hasScheme) {
      // If the backend returns a localhost URL (common in misconfigured dev environments),
      // we map it to the backendBaseUrl that the mobile device can actually reach.
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        final backendUri = Uri.parse(backendBaseUrl);
        return uri
            .replace(
              scheme: backendUri.scheme,
              host: backendUri.host,
              port: backendUri.port,
            )
            .toString();
      }
      return pathOrUrl;
    }
    final path = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    return "$backendBaseUrl$path";
  }

  void _updateCookie(http.Response response) {
    final rawCookie =
        response.headers['set-cookie'] ?? response.headers['Set-Cookie'];
    if (rawCookie != null) {
      final index = rawCookie.indexOf(';');
      _sessionCookie = (index == -1)
          ? rawCookie
          : rawCookie.substring(0, index);
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('session_cookie', _sessionCookie!);
      });
    }
  }

  // ==========================================
  // GENERIC HTTP CRUD UTILITIES
  // ==========================================

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_sessionCookie == null) {
      final prefs = await SharedPreferences.getInstance();
      _sessionCookie = prefs.getString('session_cookie');
    }
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  Future<http.Response> _rawGetRequest(String url) async {
    final headers = await _getHeaders();
    return await http
        .get(Uri.parse(url), headers: headers)
        .timeout(_requestTimeout);
  }

  Future<dynamic> getRequest(String url) async {
    try {
      final response = await _rawGetRequest(url);
      return _processResponse(response);
    } catch (e) {
      throw Exception(_friendlyRequestError(e));
    }
  }

  Future<dynamic> postRequest(String url, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(_requestTimeout);
      return _processResponse(response);
    } catch (e) {
      throw Exception(_friendlyRequestError(e));
    }
  }

  Future<dynamic> postEmptyRequest(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(Uri.parse(url), headers: headers)
          .timeout(_requestTimeout);
      return _processResponse(response);
    } catch (e) {
      throw Exception(_friendlyRequestError(e));
    }
  }

  Future<dynamic> putRequest(String url, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(_requestTimeout);
      return _processResponse(response);
    } catch (e) {
      throw Exception(_friendlyRequestError(e));
    }
  }

  Future<dynamic> deleteRequest(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(_requestTimeout);
      return _processResponse(response);
    } catch (e) {
      throw Exception(_friendlyRequestError(e));
    }
  }

  dynamic _processResponse(http.Response response) {
    _updateCookie(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String msg = "HTTP Error ${response.statusCode}";
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          msg =
              decoded['message'] ??
              decoded['error'] ??
              decoded['phoneNumberExist'] ??
              msg;
        } else if (decoded is List && decoded.isNotEmpty) {
          msg = decoded.first.toString();
        }
      } catch (_) {}
      throw Exception(ErrorTranslator.userMessage(msg));
    }
  }

  String _friendlyRequestError(Object error) {
    var raw = error.toString();
    raw = raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
    raw = raw.replaceFirst(
      RegExp(r'^(GET|POST|PUT|DELETE) Request failed:\s*'),
      '',
    );
    raw = raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (raw.contains('SocketException') ||
        raw.contains('TimeoutException') ||
        raw.contains('timed out') ||
        raw.contains('Connection refused') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Network is unreachable')) {
      return ErrorTranslator.userMessage(raw);
    }
    if (raw.contains('ClientException')) {
      return ErrorTranslator.userMessage(raw);
    }
    return ErrorTranslator.userMessage(raw);
  }

  // Local Storage Keys
  static const String _keyUser = 'api_user';
  static const String _keyCart = 'api_cart';
  static const String _keyNotifications = 'api_notifications';
  static const String _keyMessages = 'api_messages';

  // In-memory state
  UserModel? _currentUser;

  final List<StoreLocation> _mockLocations = [
    StoreLocation(
      id: 1,
      name: "Tiệm Hoa Xinh - District 1",
      address: "456 Hai Ba Trung, District 1, Ho Chi Minh City",
      phone: "0909 789 000",
      hours: "07:00 - 20:00",
      latitude: 10.7876,
      longitude: 106.6948,
    ),
    StoreLocation(
      id: 2,
      name: "Tiệm Hoa Xinh - District 3",
      address: "123 Nguyen Dinh Chieu, District 3, Ho Chi Minh City",
      phone: "0909 789 001",
      hours: "08:00 - 21:00",
      latitude: 10.7785,
      longitude: 106.6882,
    ),
  ];

  // Initialize Supabase. If credentials fail or are empty, fall back silently.
  Future<void> initializeSupabase({String? url, String? anonKey}) async {
    if (url != null &&
        anonKey != null &&
        url.isNotEmpty &&
        anonKey.isNotEmpty) {
      try {
        await Supabase.initialize(url: url, anonKey: anonKey);
        _supabase = Supabase.instance.client;
      } catch (e) {
        _supabase = null;
      }
    }
  }

  // ==========================================
  // AUTHENTICATION APIs
  // ==========================================

  Future<void> requestOtp({required String email}) async {
    try {
      await postRequest(apiRequestOtp, {"email": email});
    } catch (e) {
      throw Exception(_friendlyRequestError(e));
    }
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String otp,
  }) async {
    final response = await postRequest("$apiSignUp?otp=$otp", {
      "fullName": name,
      "phoneNumber": phone,
      "address": address,
      "email": email,
      "password": password,
    });
    final user = UserModel.fromJson(response as Map<String, dynamic>);
    await _saveLocalUser(user);
    return user;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await postRequest(apiSignIn, {
      "email": email,
      "password": password,
    });
    if (response is Map && response.containsKey('user')) {
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      await _saveLocalUser(user);
      return user;
    }
    throw Exception("Invalid response format from server");
  }

  Future<void> signOut() async {
    await getRequest(apiSignOut);
    _sessionCookie = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove('session_cookie');
  }

  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString('session_cookie');
    if (_sessionCookie == null) return null;

    try {
      final response = await getRequest(apiCurrentUser);
      if (response != null && response is Map<String, dynamic>) {
        final user = UserModel.fromJson(response);
        _currentUser = user;
        await _saveLocalUser(user);
        return user;
      }
    } catch (_) {
      _sessionCookie = null;
      await prefs.remove('session_cookie');
      await prefs.remove(_keyUser);
    }
    return null;
  }

  Future<UserModel> getProfile() async {
    dynamic response;
    try {
      response = await getRequest(apiProfile);
    } catch (_) {
      response = await getRequest(apiCurrentUser);
    }
    if (response is Map<String, dynamic>) {
      final user = UserModel.fromJson(response);
      await _saveLocalUser(user);
      return user;
    }
    throw Exception("Invalid profile response from server");
  }

  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    final response = await postRequest(apiProfileUpdate, {
      "fullName": name,
      "phoneNumber": phone,
      "address": address,
    });
    if (response is Map<String, dynamic>) {
      final user = UserModel.fromJson(response);
      await _saveLocalUser(user);
      return user;
    }
    throw Exception("Invalid update profile response from server");
  }

  Future<void> _saveLocalUser(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  // ==========================================
  // PRODUCT & CATEGORY APIs
  // ==========================================

  Future<List<Category>> getCategories() async {
    final response = await getRequest(apiAdminCategories);
    if (response is List) {
      return response
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Invalid categories response from server");
  }

  Future<List<Product>> getProducts() async {
    final response = await getRequest(apiProducts);
    if (response is List) {
      return response
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Invalid products response from server");
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final response = await getRequest("$apiCategoryProducts/$categoryId");
    if (response is Map && response['products'] is List) {
      return (response['products'] as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Invalid category products response from server");
  }

  Future<Product> getProductDetail(int productId) async {
    final response = await getRequest("$apiProductDetails/$productId");
    if (response is Map && response['product'] is Map) {
      return Product.fromJson(response['product'] as Map<String, dynamic>);
    }
    throw Exception("Invalid product detail response from server");
  }

  Future<List<Product>> getRelatedProducts(int productId) async {
    final response = await getRequest("$apiProductDetails/$productId");
    if (response is Map && response['relatedProducts'] is List) {
      return (response['relatedProducts'] as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Invalid related products response from server");
  }

  Future<List<Product>> searchProducts(String keyword) async {
    final uri = Uri.parse(
      apiProducts.replaceFirst('/all-product', '/search'),
    ).replace(queryParameters: {'keyword': keyword});
    final response = await postEmptyRequest(uri.toString());
    if (response is List) {
      return response
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Invalid search response from server");
  }

  Future<List<Map<String, dynamic>>> suggestProducts(String keyword) async {
    final uri = Uri.parse(
      apiProductSuggest,
    ).replace(queryParameters: {'keyword': keyword});
    final response = await getRequest(uri.toString());
    if (response is List) {
      return response
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();
    }
    throw Exception("Invalid product suggestions response from server");
  }

  // ==========================================
  // SHOPPING CART APIs
  // ==========================================

  Future<List<CartItem>> getCartItems(List<Product> products) async {
    final response = await getRequest(apiCart);
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
      await postRequest(apiCartAdd, {
        "productId": productId,
        "quantity": quantity,
      });
    } catch (e) {
      throw Exception(ErrorTranslator.userMessage(e));
    }
  }

  Future<void> updateCart(int productId, int quantity) async {
    try {
      await postRequest(apiCartUpdate, {
        "productId": productId,
        "quantity": quantity,
      });
    } catch (e) {
      throw Exception(ErrorTranslator.userMessage(e));
    }
  }

  Future<void> removeFromCart(int productId) async {
    try {
      await postRequest(apiCartRemove, {"productId": productId});
    } catch (e) {
      throw Exception(ErrorTranslator.userMessage(e));
    }
  }

  Future<void> saveCartItems(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = items.map((item) => item.toJson()).toList();
    await prefs.setString(_keyCart, jsonEncode(listJson));
  }

  Future<Map<String, dynamic>> getCheckoutSummary() async {
    final response = await getRequest(apiCartCheckout);
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw Exception("Invalid checkout response from server");
  }

  // ==========================================
  // ORDER APIs
  // ==========================================

  Future<List<OrderModel>> getOrders(List<Product> products) async {
    final response = await getRequest(apiOrders);
    if (response is List) {
      final List<OrderModel> orders = [];
      for (final oMap in response) {
        final map = oMap as Map<String, dynamic>;
        final List<OrderItem> orderItems = [];

        // If Backend already included orderDetails, use them directly
        if (map['orderDetails'] is List) {
          for (final detail in map['orderDetails'] as List) {
            orderItems.add(OrderItem.fromJson(detail as Map<String, dynamic>));
          }
        } else {
          // Fallback: only fetch if absolutely necessary (e.g. for user my-orders if not included)
          // But ideally Backend should include it now.
          final int orderId = map['orderId'] ?? map['id'] ?? 0;
          try {
            final detailsResponse = await getRequest(
              "$apiOrderDetail/$orderId",
            );
            if (detailsResponse is Map &&
                detailsResponse.containsKey('orderDetails')) {
              final detailsList =
                  detailsResponse['orderDetails'] as List<dynamic>;
              for (final detail in detailsList) {
                orderItems.add(
                  OrderItem.fromJson(detail as Map<String, dynamic>),
                );
              }
            }
          } catch (_) {
            // If failed to fetch details, just continue with empty items for this order in the list
          }
        }
        orders.add(OrderModel.fromJson(map, orderItems));
      }
      return orders.reversed.toList();
    }
    throw Exception("Invalid orders response from server");
  }

  Future<OrderModel> getOrderDetail(int orderId) async {
    final response = await getRequest("$apiOrderDetail/$orderId");
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
    final response = await postEmptyRequest("$apiOrderPay/$orderId");
    if (response is Map && response['redirectUrl'] is String) {
      final redirectUrl = response['redirectUrl'] as String;
      final paymentResponse = await getRequest(_backendUrl(redirectUrl));
      if (paymentResponse is Map && paymentResponse['paymentUrl'] is String) {
        return paymentResponse['paymentUrl'] as String;
      }
    }
    throw Exception("Phản hồi thanh toán lại không hợp lệ từ máy chủ");
  }

  Future<void> cancelOrder(int orderId) async {
    await postEmptyRequest("$apiOrderCancel/$orderId");
  }

  Future<void> deleteOrder(int orderId) async {
    await deleteRequest(
      "${apiOrders.replaceFirst('/my-orders', '/delete')}/$orderId",
    );
  }

  Future<List<OrderModel>> getTransactionHistory() async {
    final response = await getRequest(apiTransactionHistory);
    if (response is List) {
      return response
          .map(
            (json) =>
                OrderModel.fromJson(json as Map<String, dynamic>, const []),
          )
          .toList()
          .reversed
          .toList();
    }
    throw Exception("Phản hồi lịch sử giao dịch không hợp lệ từ máy chủ");
  }

  // ==========================================
  // VNPAY PAYMENT APIs
  // ==========================================

  Future<String> createVnpayPaymentUrl({
    required double amount,
    required String orderId,
    String ipAddress = '127.0.0.1',
  }) async {
    final uri = Uri.parse(apiPaymentCreate).replace(
      queryParameters: {
        'orderId': orderId,
        'amount': amount.toInt().toString(),
      },
    );
    final response = await getRequest(uri.toString());
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
    final response = await postRequest(apiPlaceOrder, {
      "paymentMethod": paymentMethod == "VNPAY" ? "VNPay" : "COD",
    });

    if (response is! Map || response['order'] is! Map) {
      throw Exception("Phản hồi đặt hàng không hợp lệ từ máy chủ");
    }

    String? paymentUrl;
    if (paymentMethod == "VNPAY") {
      if (response['paymentUrl'] is String) {
        paymentUrl = response['paymentUrl'] as String;
      } else if (response['redirectUrl'] is String) {
        final paymentResponse = await getRequest(
          _backendUrl(response['redirectUrl'] as String),
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
            price: c.product.hasDiscount
                ? c.product.promoPrice!
                : c.product.price,
          ),
        )
        .toList();

    final orderPayload = Map<String, dynamic>.from(
      response['order'] as Map<String, dynamic>,
    );
    if (paymentUrl != null) {
      orderPayload['paymentUrl'] = paymentUrl;
    }

    final order = OrderModel.fromJson(orderPayload, orderItems);

    await addNotification(
      title: "Đơn hàng đã đặt",
      content:
          "Cảm ơn bạn đã mua sắm. Đơn hàng #${order.id} của bạn đã được khởi tạo. Thanh toán: ${order.paymentMethod}.",
    );

    return order;
  }

  // ==========================================
  // ADMIN APIs
  // ==========================================

  Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    final response = await postRequest(apiAdminLogin, {
      'email': email,
      'password': password,
    });
    if (response is Map<String, dynamic>) return response;
    throw Exception("Phản hồi đăng nhập admin không hợp lệ từ máy chủ");
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await getRequest(apiAdminDashboard);
    if (response is Map<String, dynamic>) return response;
    throw Exception("Phản hồi dashboard admin không hợp lệ từ máy chủ");
  }

  Future<Map<String, dynamic>> getAdminOrders({
    String? email,
    String? status,
    String? startDate,
    String? endDate,
    int pageNo = 1,
  }) async {
    final query = <String, String>{'pageNo': pageNo.toString()};
    if (email != null && email.isNotEmpty) query['email'] = email;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (startDate != null && startDate.isNotEmpty) {
      query['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;
    final response = await getRequest(
      Uri.parse(apiAdminOrders).replace(queryParameters: query).toString(),
    );
    if (response is Map<String, dynamic>) return response;
    throw Exception("Phản hồi danh sách đơn hàng không hợp lệ từ máy chủ");
  }

  Future<Map<String, dynamic>> updateAdminOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final uri = Uri.parse(apiAdminOrderUpdateStatus).replace(
      queryParameters: {'orderId': orderId.toString(), 'status': status},
    );
    final response = await postEmptyRequest(uri.toString());
    if (response is Map<String, dynamic>) return response;
    throw Exception("Phản hồi cập nhật trạng thái không hợp lệ từ máy chủ");
  }

  Future<Map<String, dynamic>> getAdminProducts({
    int pageNo = 1,
    String? keyword,
  }) async {
    final query = <String, String>{'pageNo': pageNo.toString()};
    if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;
    final response = await getRequest(
      Uri.parse(apiAdminProducts).replace(queryParameters: query).toString(),
    );
    if (response is Map<String, dynamic>) return response;
    throw Exception("Phản hồi danh sách sản phẩm không hợp lệ từ máy chủ");
  }

  Future<Product> addAdminProduct(Product product) async {
    final response = await postRequest(
      apiAdminProductAdd,
      product.toBackendJson(),
    );
    if (response is Map<String, dynamic>) return Product.fromJson(response);
    throw Exception("Phản hồi thêm sản phẩm không hợp lệ từ máy chủ");
  }

  Future<Product> editAdminProduct(Product product) async {
    final response = await postRequest(
      apiAdminProductEdit,
      product.toBackendJson(),
    );
    if (response is Map<String, dynamic>) return Product.fromJson(response);
    throw Exception("Phản hồi sửa sản phẩm không hợp lệ từ máy chủ");
  }

  Future<void> deleteAdminProduct(int productId) async {
    await deleteRequest("$apiAdminProductDelete/$productId");
  }

  Future<List<Product>> getAdminComboProducts() async {
    final response = await getRequest(apiAdminProductCombo);
    if (response is List) {
      return response
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Phản hồi danh sách combo không hợp lệ từ máy chủ");
  }

  Future<Map<String, dynamic>> getAdminComboItems(int comboId) async {
    final response = await getRequest("$apiAdminProductComboAddItem/$comboId");
    if (response is Map<String, dynamic>) return response;
    throw Exception("Phản hồi chi tiết combo không hợp lệ từ máy chủ");
  }

  Future<List<dynamic>> saveAdminComboItem({
    required int comboId,
    required int productId,
    required int quantity,
  }) async {
    final uri = Uri.parse(apiAdminProductComboAddItem).replace(
      queryParameters: {
        'comboId': comboId.toString(),
        'productId': productId.toString(),
        'quantity': quantity.toString(),
      },
    );
    final response = await postEmptyRequest(uri.toString());
    if (response is List) return response;
    throw Exception("Phản hồi lưu combo không hợp lệ từ máy chủ");
  }

  Future<List<dynamic>> removeAdminComboItem(int comboItemId) async {
    final response = await deleteRequest(
      "$apiAdminProductComboRemoveItem/$comboItemId",
    );
    if (response is List) return response;
    throw Exception("Phản hồi xóa combo không hợp lệ từ máy chủ");
  }

  Future<Map<String, dynamic>> getAdminUsers({
    int pageNo = 1,
    String? search,
  }) async {
    final query = <String, String>{'pageNo': pageNo.toString()};
    if (search != null && search.isNotEmpty) query['search'] = search;
    final response = await getRequest(
      Uri.parse(apiAdminUsers).replace(queryParameters: query).toString(),
    );
    if (response is Map<String, dynamic>) return response;
    throw Exception("Phản hồi danh sách user không hợp lệ từ máy chủ");
  }

  Future<UserModel> activateAdminUser(int userId) async {
    final response = await postEmptyRequest("$apiAdminUserActivate/$userId");
    if (response is Map<String, dynamic>) return UserModel.fromJson(response);
    throw Exception("Phản hồi kích hoạt user không hợp lệ từ máy chủ");
  }

  Future<UserModel> deactivateAdminUser(int userId) async {
    final response = await postEmptyRequest("$apiAdminUserDeactivate/$userId");
    if (response is Map<String, dynamic>) return UserModel.fromJson(response);
    throw Exception("Phản hồi vô hiệu hóa user không hợp lệ từ máy chủ");
  }

  Future<UserModel> updateAdminUserRole({
    required int userId,
    required int roleId,
  }) async {
    final uri = Uri.parse(
      "$apiAdminUserUpdateRole/$userId",
    ).replace(queryParameters: {'roleId': roleId.toString()});
    final response = await postEmptyRequest(uri.toString());
    if (response is Map<String, dynamic>) return UserModel.fromJson(response);
    throw Exception("Phản hồi cập nhật quyền không hợp lệ từ máy chủ");
  }

  // ==========================================
  // NOTIFICATION APIs
  // ==========================================

  Future<List<NotificationModel>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notifStr = prefs.getString(_keyNotifications);

    if (notifStr == null) {
      // Seed default notifications
      final defaultNotifs = [
        NotificationModel(
          id: 1,
          title: "Chào mừng đến với Tiệm Hoa Xinh",
          content:
              "Những bông hoa tươi tắn nhất đã sẵn sàng giao đến bạn. Hãy đăng nhập để khám phá các mẫu hoa cao cấp.",
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          isRead: false,
        ),
        NotificationModel(
          id: 2,
          title: "Khuyến mãi đặc biệt",
          content:
              "Giảm giá lên đến 20% cho tất cả các bó hoa hồng sang trọng trong cuối tuần này.",
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
        ),
      ];
      await saveNotifications(defaultNotifs);
      return defaultNotifs;
    }

    try {
      final List<dynamic> list = jsonDecode(notifStr) as List<dynamic>;
      return list
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotifications(List<NotificationModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final notifJson = list.map((n) => n.toJson()).toList();
    await prefs.setString(_keyNotifications, jsonEncode(notifJson));
  }

  Future<void> addNotification({
    required String title,
    required String content,
  }) async {
    final list = await getNotifications();
    final newId = list.isEmpty
        ? 1
        : list.map((n) => n.id).reduce((a, b) => a > b ? a : b) + 1;
    list.insert(
      0,
      NotificationModel(
        id: newId,
        title: title,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
    await saveNotifications(list);
  }

  // ==========================================
  // MESSAGING / CHAT APIs
  // ==========================================

  Future<List<MessageModel>> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final msgStr = prefs.getString(_keyMessages);

    if (msgStr == null) {
      // Seed default support welcoming message
      final defaultMsgs = [
        MessageModel(
          id: 1,
          content:
              "Welcome to Tiệm Hoa Xinh! Let us know if you have questions regarding flower care, delivery options, or boutique options. We are here to assist.",
          sender: "store",
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];
      await saveMessages(defaultMsgs);
      return defaultMsgs;
    }

    try {
      final List<dynamic> list = jsonDecode(msgStr) as List<dynamic>;
      return list
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMessages(List<MessageModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final msgJson = list.map((m) => m.toJson()).toList();
    await prefs.setString(_keyMessages, jsonEncode(msgJson));
  }

  Future<MessageModel> sendMessage(String content, String sender) async {
    if (content.trim().isEmpty) {
      throw Exception("Message content cannot be empty.");
    }

    final list = await getMessages();
    final newId = list.isEmpty
        ? 1
        : list.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;

    final message = MessageModel(
      id: newId,
      content: content,
      sender: sender,
      timestamp: DateTime.now(),
    );

    list.add(message);
    await saveMessages(list);

    // Sync to Supabase if available
    if (isSupabaseInitialized && _currentUser != null) {
      try {
        final mJson = message.toJson();
        mJson['user_id'] = _currentUser!.id;
        await _supabase!.from('messages').insert(mJson);
      } catch (_) {}
    }

    return message;
  }

  // Simulates a store representative response based on user input terms.
  Future<MessageModel?> getMockAutoReply(String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final normalized = userMessage.toLowerCase();
    String reply =
        "Thank you for reaching out. We have received your query and will reply shortly.";

    if (normalized.contains("giá") ||
        normalized.contains("price") ||
        normalized.contains("mua")) {
      reply =
          "Our flower bouquets range from 35.00 to 65.00. We currently have sales on Blush Romance and Spring Tulip Symphony! Check our Home Page for prices.";
    } else if (normalized.contains("ship") ||
        normalized.contains("giao") ||
        normalized.contains("delivery")) {
      reply =
          "We offer same-day delivery across Ho Chi Minh City for orders placed before 16:00. Standard shipping is 5.00, and free for orders over 100.00.";
    } else if (normalized.contains("bảo hành") ||
        normalized.contains("chăm sóc") ||
        normalized.contains("care") ||
        normalized.contains("tươi")) {
      reply =
          "To keep your flowers fresh: trim stems at 45 degrees, place in cold fresh water with flower food, and keep away from heat/direct sunlight.";
    } else if (normalized.contains("địa chỉ") ||
        normalized.contains("map") ||
        normalized.contains("address") ||
        normalized.contains("ở đâu")) {
      reply =
          "Our main store is located at 456 Hai Ba Trung, District 1, Ho Chi Minh City. You can check the Map section for working hours and directions.";
    }

    return await sendMessage(reply, "store");
  }

  // ==========================================
  // STORE LOCATION APIs
  // ==========================================

  Future<List<StoreLocation>> getStoreLocations() async {
    if (isSupabaseInitialized) {
      try {
        final List<dynamic> data = await _supabase!
            .from('store_locations')
            .select();
        return data
            .map((json) => StoreLocation.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return _mockLocations;
      }
    }
    return _mockLocations;
  }
}
