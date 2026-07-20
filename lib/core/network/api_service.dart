import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prm393/features/catalog/models/category.dart';
import 'package:prm393/features/catalog/models/product.dart';
import 'package:prm393/features/catalog/models/review.dart';
import 'package:prm393/features/auth/models/user.dart';
import 'package:prm393/features/cart/models/cart_item.dart';
import 'package:prm393/features/orders/models/order.dart';
import 'package:prm393/features/notifications/models/app_notification.dart';
import 'package:prm393/features/chat/models/message.dart';
import 'package:prm393/features/chat/models/conversation_summary.dart';
import 'package:prm393/features/stores/models/store_location.dart';
import 'package:prm393/core/utils/error_translator.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ==========================================
  // API URL CONSTANTS & CONFIGURATIONS
  //
  // Backend host comes from (in priority order):
  //   1. --dart-define=API_BASE_URL=... passed to `flutter run`/`flutter build`
  //   2. API_BASE_URL (or API_HOST + API_PORT) in the gitignored .env file at
  //      the project root — copy .env.example -> .env and fill in your own
  //      machine's LAN IP/port (needed for physical devices; 10.0.2.2 below
  //      only resolves on the Android emulator, not real devices)
  //   3. _fallbackLanIp / _fallbackPort below, if none of the above is set
  // ==========================================

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _fallbackLanIp = '192.168.1.10';
  static const int _fallbackPort = 3636;

  static String get backendBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;

    final fullUrl = dotenv.maybeGet('API_BASE_URL');
    if (fullUrl != null && fullUrl.isNotEmpty) return fullUrl;

    if (kIsWeb) return 'http://localhost:$_fallbackPort';

    final host = dotenv.maybeGet('API_HOST') ?? _fallbackLanIp;
    final port = dotenv.maybeGet('API_PORT') ?? _fallbackPort.toString();
    return 'http://$host:$port';
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
  static String get apiOrderConfirmReceived =>
      "$backendBaseUrl/order/confirm-received";
  static String get apiPaymentCreate => "$backendBaseUrl/payment/create";

  // Reviews Routes
  static String apiProductReviews(int productId) =>
      "$backendBaseUrl/api/products/$productId/reviews";

  // Admin Routes
  static String get apiAdminLogin => "$backendBaseUrl/admin/login";
  static String get apiAdminDashboard => "$backendBaseUrl/admin/dashboard";
  static String get apiAdminOrders => "$backendBaseUrl/admin/orders";
  static String get apiAdminOrderDetail =>
      "$backendBaseUrl/admin/orders/detail";
  static String get apiAdminOrderUpdateStatus =>
      "$backendBaseUrl/admin/orders/update-status";
  static String get apiAdminProducts => "$backendBaseUrl/admin/products";
  static String get apiAdminProductAdd => "$backendBaseUrl/admin/products/add";
  static String get apiAdminProductEdit =>
      "$backendBaseUrl/admin/products/edit";
  static String get apiAdminProductDelete =>
      "$backendBaseUrl/admin/products/delete";
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

  static const Duration _requestTimeout = Duration(seconds: 10);

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
  // PRODUCT REVIEWS APIs
  // ==========================================

  Future<ProductReviewsSummary> getProductReviews(int productId) async {
    final response = await getRequest(apiProductReviews(productId));
    if (response is Map<String, dynamic>) {
      return ProductReviewsSummary.fromJson(response);
    }
    throw Exception("Invalid reviews response from server");
  }

  Future<ReviewModel> submitProductReview(
    int productId, {
    required int rating,
    String comment = '',
  }) async {
    final response = await postRequest(apiProductReviews(productId), {
      "rating": rating,
      "comment": comment,
    });
    if (response is Map<String, dynamic>) {
      return ReviewModel.fromJson(response);
    }
    throw Exception("Invalid review response from server");
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

  Future<List<OrderModel>> getOrders(
    List<Product> products, {
    String? status,
  }) async {
    final url = (status == null || status.isEmpty)
        ? apiOrders
        : Uri.parse(
            apiOrders,
          ).replace(queryParameters: {'status': status}).toString();
    final response = await getRequest(url);
    if (response is List) {
      final List<OrderModel> orders = [];
      for (final oMap in response) {
        final map = oMap as Map<String, dynamic>;
        // /order/my-orders already inlines orderDetails per order — no need
        // to fetch each order's detail separately (that was an N+1 fan-out).
        final List<OrderItem> orderItems = [];
        final detailsList = map['orderDetails'];
        if (detailsList is List) {
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
    throw Exception("Invalid repay response from server");
  }

  Future<void> cancelOrder(int orderId) async {
    await postEmptyRequest("$apiOrderCancel/$orderId");
  }

  Future<void> confirmOrderReceived(int orderId) async {
    await postEmptyRequest("$apiOrderConfirmReceived/$orderId");
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
      throw Exception("Invalid place order response from server");
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
    throw Exception("Invalid admin login response from server");
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await getRequest(apiAdminDashboard);
    if (response is Map<String, dynamic>) return response;
    throw Exception("Invalid admin dashboard response from server");
  }

  Future<Map<String, dynamic>> getAdminOrders({
    String? email,
    String? status,
    String? paymentStatus,
    String? startDate,
    String? endDate,
    int pageNo = 1,
  }) async {
    final query = <String, String>{'pageNo': pageNo.toString()};
    if (email != null && email.isNotEmpty) query['email'] = email;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      query['paymentStatus'] = paymentStatus;
    }
    if (startDate != null && startDate.isNotEmpty) {
      query['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;
    final response = await getRequest(
      Uri.parse(apiAdminOrders).replace(queryParameters: query).toString(),
    );
    if (response is Map<String, dynamic>) return response;
    throw Exception("Invalid admin orders response from server");
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
    throw Exception("Invalid update order status response from server");
  }

  Future<OrderModel> getAdminOrderDetail(int orderId) async {
    final response = await getRequest("$apiAdminOrderDetail/$orderId");
    if (response is Map && response['orderDetails'] is List) {
      final detailsList = response['orderDetails'] as List;
      if (detailsList.isEmpty) {
        throw Exception("Đơn hàng không có sản phẩm nào");
      }
      final firstDetail = detailsList.first as Map<String, dynamic>;
      final orderMap = firstDetail['order'] as Map<String, dynamic>?;
      if (orderMap == null) {
        throw Exception("Không tìm thấy thông tin đơn hàng");
      }
      final items = detailsList
          .map((json) => OrderItem.fromJson(json as Map<String, dynamic>))
          .toList();
      return OrderModel.fromJson(orderMap, items);
    }
    throw Exception("Invalid admin order detail response from server");
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
    throw Exception("Invalid admin products response from server");
  }

  Future<Product> addAdminProduct(Product product) async {
    final response = await postRequest(
      apiAdminProductAdd,
      product.toBackendJson(),
    );
    if (response is Map<String, dynamic>) return Product.fromJson(response);
    throw Exception("Invalid add product response from server");
  }

  Future<Product> editAdminProduct(Product product) async {
    final response = await postRequest(
      apiAdminProductEdit,
      product.toBackendJson(),
    );
    if (response is Map<String, dynamic>) return Product.fromJson(response);
    throw Exception("Invalid edit product response from server");
  }

  Future<void> deleteAdminProduct(int productId) async {
    await deleteRequest("$apiAdminProductDelete/$productId");
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
    throw Exception("Invalid admin users response from server");
  }

  Future<UserModel> activateAdminUser(int userId) async {
    final response = await postEmptyRequest("$apiAdminUserActivate/$userId");
    if (response is Map<String, dynamic>) return UserModel.fromJson(response);
    throw Exception("Invalid activate user response from server");
  }

  Future<UserModel> deactivateAdminUser(int userId) async {
    final response = await postEmptyRequest("$apiAdminUserDeactivate/$userId");
    if (response is Map<String, dynamic>) return UserModel.fromJson(response);
    throw Exception("Invalid deactivate user response from server");
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
    throw Exception("Invalid update user role response from server");
  }

  // ==========================================
  // NOTIFICATION APIs (server-side, per user)
  // ==========================================

  static String get apiNotifications => "$backendBaseUrl/api/notifications";
  static String apiNotificationRead(int id) =>
      "$backendBaseUrl/api/notifications/$id/read";
  static String get apiNotificationsReadAll =>
      "$backendBaseUrl/api/notifications/read-all";

  Future<List<NotificationModel>> getNotifications() async {
    final response = await getRequest(apiNotifications);
    if (response is List) {
      return response
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }
    throw Exception("Invalid notifications response from server");
  }

  Future<void> markNotificationRead(int notificationId) async {
    await postEmptyRequest(apiNotificationRead(notificationId));
  }

  Future<void> markAllNotificationsRead() async {
    await postEmptyRequest(apiNotificationsReadAll);
  }

  // ==========================================
  // MESSAGING / CHAT APIs (real-time via WebSocket, REST for history)
  // ==========================================

  static String get wsBaseUrl =>
      backendBaseUrl.replaceFirst(RegExp(r'^http'), 'ws');
  static String get wsChatUrl => "$wsBaseUrl/ws/chat";

  static String get apiChatConversation =>
      "$backendBaseUrl/api/chat/conversation";
  static String get apiChatConversations =>
      "$backendBaseUrl/api/chat/conversations";
  static String apiChatConversationMessages(int conversationId) =>
      "$backendBaseUrl/api/chat/conversations/$conversationId/messages";
  static String get apiChatSendMyMessage => "$backendBaseUrl/api/chat/messages";
  static String apiChatMarkRead(int conversationId) =>
      "$backendBaseUrl/api/chat/conversations/$conversationId/read";
  static String get apiChatUnreadCount =>
      "$backendBaseUrl/api/chat/unread-count";

  // The session cookie carrying auth, needed to authenticate the WebSocket handshake.
  Future<String?> getSessionCookie() async {
    if (_sessionCookie == null) {
      final prefs = await SharedPreferences.getInstance();
      _sessionCookie = prefs.getString('session_cookie');
    }
    return _sessionCookie;
  }

  // Customer: fetch (or implicitly create) their own conversation + full history.
  Future<Map<String, dynamic>> getMyConversation() async {
    final result = await getRequest(apiChatConversation);
    return result as Map<String, dynamic>;
  }

  // Admin: list of all customer conversations with last message + unread count.
  Future<List<ConversationSummary>> getConversations() async {
    final result = await getRequest(apiChatConversations);
    return (result as List<dynamic>)
        .map(
          (json) => ConversationSummary.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<MessageModel>> getConversationMessages(int conversationId) async {
    final result = await getRequest(
      apiChatConversationMessages(conversationId),
    );
    return (result as List<dynamic>)
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Customer sends a message in their own conversation.
  Future<MessageModel> sendMyMessage(String content) async {
    final result = await postRequest(apiChatSendMyMessage, {
      'content': content,
    });
    return MessageModel.fromJson(result as Map<String, dynamic>);
  }

  // Admin replies in a specific conversation.
  Future<MessageModel> sendMessageToConversation(
    int conversationId,
    String content,
  ) async {
    final result = await postRequest(
      apiChatConversationMessages(conversationId),
      {'content': content},
    );
    return MessageModel.fromJson(result as Map<String, dynamic>);
  }

  Future<void> markConversationRead(int conversationId) async {
    await postEmptyRequest(apiChatMarkRead(conversationId));
  }

  Future<int> getUnreadChatCount() async {
    final result = await getRequest(apiChatUnreadCount);
    final count = (result as Map<String, dynamic>)['unreadCount'];
    return count is int ? count : int.tryParse(count.toString()) ?? 0;
  }

  // ==========================================
  // STORE LOCATION APIs
  // ==========================================

  static String get apiStoreLocations => "$backendBaseUrl/api/store-locations";

  Future<List<StoreLocation>> getStoreLocations() async {
    try {
      final response = await getRequest(apiStoreLocations);
      if (response is List && response.isNotEmpty) {
        return response
            .map((json) => StoreLocation.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Backend không truy cập được — dùng dữ liệu dự phòng bên dưới
    }
    return _mockLocations;
  }
}
