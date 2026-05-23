import 'dart:async';
import 'dart:convert';
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

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ==========================================
  // API URL CONSTANTS & CONFIGURATIONS
  // ==========================================
  
  // Base URLs
  static const String backendBaseUrl = "https://api.tiemhoaxinh.vn/api/v1";
  static const String defaultSupabaseUrl = "https://your-project-id.supabase.co";
  static const String defaultSupabaseAnonKey = "your-anon-key-here";

  // Auth Routes
  static const String apiSignIn = "$backendBaseUrl/auth/signin";
  static const String apiSignUp = "$backendBaseUrl/auth/signup";
  static const String apiSignOut = "$backendBaseUrl/auth/signout";
  static const String apiProfile = "$backendBaseUrl/user/profile";

  // Catalog & Shopping Routes
  static const String apiProducts = "$backendBaseUrl/products";
  static const String apiCategories = "$backendBaseUrl/categories";
  static const String apiCart = "$backendBaseUrl/cart";
  static const String apiOrders = "$backendBaseUrl/orders";
  
  // Support, Stores & Notifications Routes
  static const String apiNotifications = "$backendBaseUrl/notifications";
  static const String apiMessages = "$backendBaseUrl/messages";
  static const String apiStoreLocations = "$backendBaseUrl/stores";

  // Payment Gateway Routes
  static const String apiVnpayCreate = "$backendBaseUrl/payment/vnpay/create";
  static const String vnpaySandboxUrl = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";

  SupabaseClient? _supabase;
  bool get isSupabaseInitialized => _supabase != null;

  // ==========================================
  // GENERIC HTTP CRUD UTILITIES
  // ==========================================

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_keyUser);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (userStr != null) {
      try {
        final userMap = jsonDecode(userStr) as Map<String, dynamic>;
        final token = userMap['id'] as String;
        // Prefixes standard mock authorization headers if needed
        headers['Authorization'] = 'Bearer $token';
      } catch (_) {}
    }
    return headers;
  }

  Future<dynamic> getRequest(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception("GET Request failed: $e");
    }
  }

  Future<dynamic> postRequest(String url, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception("POST Request failed: $e");
    }
  }

  Future<dynamic> putRequest(String url, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception("PUT Request failed: $e");
    }
  }

  Future<dynamic> deleteRequest(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse(url), headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception("DELETE Request failed: $e");
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String msg = "HTTP Error ${response.statusCode}";
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        msg = err['message'] ?? err['error'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // Local Storage Keys
  static const String _keyUser = 'api_user';
  static const String _keyCart = 'api_cart';
  static const String _keyOrders = 'api_orders';
  static const String _keyNotifications = 'api_notifications';
  static const String _keyMessages = 'api_messages';

  // In-Memory Fallback State (initialized with mock data)
  UserModel? _currentUser;
  final List<Category> _mockCategories = [
    Category(id: 1, name: "Birthday Flowers"),
    Category(id: 2, name: "Anniversary Flowers"),
    Category(id: 3, name: "Congratulatory Flowers"),
    Category(id: 4, name: "Love and Romance"),
  ];

  final List<Product> _mockProducts = [
    Product(
      id: 101,
      name: "Blush Romance Rose",
      categoryId: 4,
      imageUrl: "https://images.unsplash.com/photo-1561181286-d3fee7d55364?w=500",
      price: 45.0,
      promoPrice: 39.99,
      description: "A gorgeous arrangement of hand-picked soft pink roses styled with fresh eucalyptus leaves. Perfect for expressing love and romantic affection.",
      careInstructions: "Trim stems at a 45-degree angle, change the water daily, and keep away from direct sunlight and heat sources.",
      stock: 12,
      isAvailable: true,
      flowerType: "Rose",
      color: "Pink",
      size: "Medium",
      freshness: "Premium Fresh",
    ),
    Product(
      id: 102,
      name: "Golden Sunburst Bouquet",
      categoryId: 1,
      imageUrl: "https://images.unsplash.com/photo-1597848212624-a19eb35e2651?w=500",
      price: 35.0,
      description: "Bright and cheerful sunflowers matched with yellow daisies and fresh greens. Guaranteed to bring warmth and happiness to anyone on their birthday.",
      careInstructions: "Provide plenty of water, keep in a cool environment, and prune lower leaves that submerge in water.",
      stock: 8,
      isAvailable: true,
      flowerType: "Sunflower",
      color: "Yellow",
      size: "Medium",
      freshness: "Freshly Cut",
    ),
    Product(
      id: 103,
      name: "Ruby Passion Roses",
      categoryId: 4,
      imageUrl: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=500",
      price: 55.0,
      promoPrice: 49.00,
      description: "An elegant classic bouquet of deep crimson red roses. Exquisite craftsmanship to declare passionate sentiments and timeless elegance.",
      careInstructions: "Cut the stems under running water, add flower food to the vase, and keep in a cool draft-free spot.",
      stock: 15,
      isAvailable: true,
      flowerType: "Rose",
      color: "Red",
      size: "Large",
      freshness: "Premium Fresh",
    ),
    Product(
      id: 104,
      name: "Elegant Orchid Delight",
      categoryId: 3,
      imageUrl: "https://images.unsplash.com/photo-1525253086316-d0c936c814f8?w=500",
      price: 65.0,
      description: "Stunning purple orchids arranged in a premium ceramic pot. A symbol of luxury, beauty, and strength, ideal for congratulations and grand openings.",
      careInstructions: "Water moderately once a week, allow soil to dry between waterings, and keep in indirect bright sunlight.",
      stock: 5,
      isAvailable: true,
      flowerType: "Orchid",
      color: "Purple",
      size: "Medium",
      freshness: "Long-lasting Blooms",
    ),
    Product(
      id: 105,
      name: "White Lily Serenade",
      categoryId: 2,
      imageUrl: "https://images.unsplash.com/photo-1525310072745-f49212b5ac6d?w=500",
      price: 48.0,
      description: "Graceful pure white lilies coupled with baby's breath. Delivers a peaceful and celebratory aura, making it excellent for anniversary celebrations.",
      careInstructions: "Remove the pollen-bearing anthers to prevent staining and prolong blossom life. Refill clean water regularly.",
      stock: 0,
      isAvailable: false,
      flowerType: "Lily",
      color: "White",
      size: "Large",
      freshness: "Budding to Open",
    ),
    Product(
      id: 106,
      name: "Spring Tulip Symphony",
      categoryId: 1,
      imageUrl: "https://images.unsplash.com/photo-1520763185298-1b434c919102?w=500",
      price: 40.0,
      promoPrice: 34.99,
      description: "A vibrant combination of colorful spring tulips. Expresses playful joy and appreciation, bound nicely with silk ribbons.",
      careInstructions: "Keep in very cold water. Tulips continue to grow in the vase, so rotate periodically to prevent bending.",
      stock: 20,
      isAvailable: true,
      flowerType: "Tulip",
      color: "Mixed Colors",
      size: "Medium",
      freshness: "Freshly Harvested",
    ),
  ];

  final List<StoreLocation> _mockLocations = [
    StoreLocation(
      id: 1,
      name: "Tiem Hoa Xinh - District 1",
      address: "456 Hai Ba Trung, District 1, Ho Chi Minh City",
      phone: "0909 789 000",
      hours: "07:00 - 20:00",
      latitude: 10.7876,
      longitude: 106.6948,
    ),
    StoreLocation(
      id: 2,
      name: "Tiem Hoa Xinh - District 3",
      address: "123 Nguyen Dinh Chieu, District 3, Ho Chi Minh City",
      phone: "0909 789 001",
      hours: "08:00 - 21:00",
      latitude: 10.7785,
      longitude: 106.6882,
    ),
  ];

  // Initialize Supabase. If credentials fail or are empty, fall back silently.
  Future<void> initializeSupabase({String? url, String? anonKey}) async {
    if (url != null && anonKey != null && url.isNotEmpty && anonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: url,
          anonKey: anonKey,
        );
        _supabase = Supabase.instance.client;
      } catch (e) {
        _supabase = null;
      }
    }
  }

  // ==========================================
  // AUTHENTICATION APIs
  // ==========================================

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    if (isSupabaseInitialized) {
      try {
        final authResponse = await _supabase!.auth.signUp(
          email: email,
          password: password,
          data: {
            'name': name,
            'phone': phone,
            'address': address,
          },
        );

        if (authResponse.user == null) {
          throw Exception("Signup failed. User returned is null.");
        }

        final user = UserModel(
          id: authResponse.user!.id,
          email: email,
          name: name,
          phone: phone,
          address: address,
        );

        // Save profile metadata in Supabase
        await _supabase!.from('profiles').upsert(user.toJson());
        
        await _saveLocalUser(user);
        return user;
      } catch (e) {
        // Fallback to local on error or continue with throwing if preferred
        return _mockSignUp(email, password, name, phone, address);
      }
    } else {
      return _mockSignUp(email, password, name, phone, address);
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    if (isSupabaseInitialized) {
      try {
        final authResponse = await _supabase!.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (authResponse.user == null) {
          throw Exception("Invalid credentials.");
        }

        // Fetch profile details
        final profileData = await _supabase!
            .from('profiles')
            .select()
            .eq('id', authResponse.user!.id)
            .single();

        final user = UserModel.fromJson(profileData);
        await _saveLocalUser(user);
        return user;
      } catch (e) {
        return _mockSignIn(email, password);
      }
    } else {
      return _mockSignIn(email, password);
    }
  }

  Future<void> signOut() async {
    if (isSupabaseInitialized) {
      try {
        await _supabase!.auth.signOut();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    _currentUser = null;
  }

  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_keyUser);
    if (userStr != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userStr) as Map<String, dynamic>);
      return _currentUser;
    }

    if (isSupabaseInitialized) {
      final session = _supabase!.auth.currentSession;
      if (session != null) {
        try {
          final profileData = await _supabase!
              .from('profiles')
              .select()
              .eq('id', session.user.id)
              .single();
          final user = UserModel.fromJson(profileData);
          await _saveLocalUser(user);
          return user;
        } catch (_) {}
      }
    }
    return null;
  }

  Future<void> _saveLocalUser(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<UserModel> _mockSignUp(String email, String password, String name, String phone, String address) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception("Please fill in all required fields.");
    }
    if (!email.contains('@')) {
      throw Exception("Please enter a valid email address.");
    }
    if (password.length < 6) {
      throw Exception("Password must be at least 6 characters long.");
    }

    final user = UserModel(
      id: "mock_user_${DateTime.now().millisecondsSinceEpoch}",
      email: email,
      name: name,
      phone: phone,
      address: address,
    );
    await _saveLocalUser(user);
    return user;
  }

  Future<UserModel> _mockSignIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty || password.isEmpty) {
      throw Exception("Please enter both email and password.");
    }
    if (!email.contains('@')) {
      throw Exception("Please enter a valid email address.");
    }
    if (password == "error123") {
      throw Exception("Email or password is incorrect.");
    }

    // Default mock login credentials (accepts any email matching password '123456' for ease of testing)
    if (password != "123456") {
      throw Exception("Email or password is incorrect.");
    }

    final user = UserModel(
      id: "mock_user_123",
      email: email,
      name: "Vinh Flowerist",
      phone: "0909 123 456",
      address: "123 Le Loi, District 1, Ho Chi Minh City",
    );
    await _saveLocalUser(user);
    return user;
  }

  // ==========================================
  // PRODUCT & CATEGORY APIs
  // ==========================================

  Future<List<Category>> getCategories() async {
    if (isSupabaseInitialized) {
      try {
        final List<dynamic> data = await _supabase!.from('categories').select();
        return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        return _mockCategories;
      }
    }
    return _mockCategories;
  }

  Future<List<Product>> getProducts() async {
    if (isSupabaseInitialized) {
      try {
        final List<dynamic> data = await _supabase!.from('products').select();
        return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        return _mockProducts;
      }
    }
    return _mockProducts;
  }

  // ==========================================
  // SHOPPING CART APIs
  // ==========================================

  Future<List<CartItem>> getCartItems(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final cartStr = prefs.getString(_keyCart);
    if (cartStr == null) return [];

    try {
      final List<dynamic> list = jsonDecode(cartStr) as List<dynamic>;
      final List<CartItem> items = [];
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final pId = map['product_id'] as int;
        final product = products.firstWhere((p) => p.id == pId, orElse: () => _mockProducts.first);
        items.add(CartItem.fromJson(map, product));
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCartItems(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = items.map((item) => item.toJson()).toList();
    await prefs.setString(_keyCart, jsonEncode(listJson));

    if (isSupabaseInitialized && _currentUser != null) {
      try {
        // Sync to Supabase in a background thread
        await _supabase!.from('carts').upsert({
          'user_id': _currentUser!.id,
          'items': listJson,
        });
      } catch (_) {}
    }
  }

  // ==========================================
  // ORDER APIs
  // ==========================================

  Future<List<OrderModel>> getOrders(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersStr = prefs.getString(_keyOrders);
    if (ordersStr == null) return [];

    try {
      final List<dynamic> list = jsonDecode(ordersStr) as List<dynamic>;
      final List<OrderModel> orders = [];
      for (final oMap in list) {
        final map = oMap as Map<String, dynamic>;
        final List<dynamic> itemsJson = map['items'] as List<dynamic>;
        final List<OrderItem> orderItems = [];
        for (final itemMap in itemsJson) {
          final pId = itemMap['product_id'] as int;
          final product = products.firstWhere((p) => p.id == pId, orElse: () => _mockProducts.first);
          orderItems.add(OrderItem.fromJson(itemMap as Map<String, dynamic>, product));
        }
        orders.add(OrderModel.fromJson(map, orderItems));
      }
      return orders.reversed.toList(); // Newest first
    } catch (_) {
      return [];
    }
  }

  // ==========================================
  // VNPAY PAYMENT APIs
  // ==========================================

  Future<String> createVnpayPaymentUrl({
    required double amount,
    required String orderId,
    String ipAddress = '127.0.0.1',
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // In actual Supabase/REST backend:
    // If Supabase is initialized, we trigger an edge function
    if (isSupabaseInitialized) {
      try {
        final response = await _supabase!.functions.invoke('vnpay-create-payment', body: {
          'amount': amount,
          'orderId': orderId,
          'ipAddress': ipAddress,
        });
        final data = jsonDecode(response.data as String) as Map<String, dynamic>;
        return data['paymentUrl'] as String;
      } catch (_) {}
    }

    // Local sandbox simulation URL
    final amountInVnd = (amount * 25000).toInt(); // Conversion rate of 1 USD = 25,000 VND
    return "$vnpaySandboxUrl"
        "?vnp_Amount=$amountInVnd"
        "&vnp_Command=pay"
        "&vnp_CreateDate=${DateTime.now().millisecondsSinceEpoch}"
        "&vnp_CurrCode=VND"
        "&vnp_IpAddr=$ipAddress"
        "&vnp_Locale=vn"
        "&vnp_OrderInfo=Thanh+toan+don+hang+$orderId"
        "&vnp_OrderType=other"
        "&vnp_ReturnUrl=http%3A%2F%2Flocalhost%3A8080%2Fvnpay_return"
        "&vnp_TmnCode=DEMO0001"
        "&vnp_TxnRef=$orderId"
        "&vnp_Version=2.1.0";
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
    await Future.delayed(const Duration(milliseconds: 800));

    final newOrderId = DateTime.now().millisecondsSinceEpoch;
    final orderItems = cartItems.map((c) => OrderItem(
      id: newOrderId + c.product.id,
      product: c.product,
      quantity: c.quantity,
      price: c.product.promoPrice ?? c.product.price,
    )).toList();

    final order = OrderModel(
      id: newOrderId,
      totalAmount: totalAmount,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      status: status,
      createdAt: DateTime.now(),
      items: orderItems,
    );

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders(_mockProducts);
    orders.add(order);

    final ordersJson = orders.map((o) {
      final map = o.toJson();
      map['items'] = o.items.map((i) => i.toJson()).toList();
      return map;
    }).toList();

    await prefs.setString(_keyOrders, jsonEncode(ordersJson));
    await prefs.remove(_keyCart); // Clear local cart

    if (isSupabaseInitialized && _currentUser != null) {
      try {
        final orderMap = order.toJson();
        orderMap['user_id'] = _currentUser!.id;
        await _supabase!.from('orders').insert(orderMap);

        final itemsMap = order.items.map((i) {
          final iMap = i.toJson();
          iMap['order_id'] = order.id;
          return iMap;
        }).toList();
        await _supabase!.from('order_items').insert(itemsMap);
        await _supabase!.from('carts').delete().eq('user_id', _currentUser!.id);
      } catch (_) {}
    }

    // Trigger confirmation notification
    await addNotification(
      title: "Order Confirmed",
      content: "Thank you for shopping. Your order of flower boutique (ID: $newOrderId) is confirmed and prepared for shipping. Payment status: $status.",
    );

    return order;
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
          title: "Welcome to Tiem Hoa Xinh",
          content: "Get fresh blossoms delivered to your door. Log in and discover premium floral catalogs.",
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          isRead: false,
        ),
        NotificationModel(
          id: 2,
          title: "Special Anniversary Promo",
          content: "Enjoy up to 20% discount on all elegant rose bouquets this weekend.",
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
        ),
      ];
      await saveNotifications(defaultNotifs);
      return defaultNotifs;
    }

    try {
      final List<dynamic> list = jsonDecode(notifStr) as List<dynamic>;
      return list.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotifications(List<NotificationModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final notifJson = list.map((n) => n.toJson()).toList();
    await prefs.setString(_keyNotifications, jsonEncode(notifJson));
  }

  Future<void> addNotification({required String title, required String content}) async {
    final list = await getNotifications();
    final newId = list.isEmpty ? 1 : list.map((n) => n.id).reduce((a, b) => a > b ? a : b) + 1;
    list.insert(0, NotificationModel(
      id: newId,
      title: title,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
    ));
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
          content: "Welcome to Tiem Hoa Xinh! Let us know if you have questions regarding flower care, delivery options, or boutique options. We are here to assist.",
          sender: "store",
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        )
      ];
      await saveMessages(defaultMsgs);
      return defaultMsgs;
    }

    try {
      final List<dynamic> list = jsonDecode(msgStr) as List<dynamic>;
      return list.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
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
    final newId = list.isEmpty ? 1 : list.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;
    
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
    String reply = "Thank you for reaching out. We have received your query and will reply shortly.";

    if (normalized.contains("giá") || normalized.contains("price") || normalized.contains("mua")) {
      reply = "Our flower bouquets range from 35.00 to 65.00. We currently have sales on Blush Romance and Spring Tulip Symphony! Check our Home Page for prices.";
    } else if (normalized.contains("ship") || normalized.contains("giao") || normalized.contains("delivery")) {
      reply = "We offer same-day delivery across Ho Chi Minh City for orders placed before 16:00. Standard shipping is 5.00, and free for orders over 100.00.";
    } else if (normalized.contains("bảo hành") || normalized.contains("chăm sóc") || normalized.contains("care") || normalized.contains("tươi")) {
      reply = "To keep your flowers fresh: trim stems at 45 degrees, place in cold fresh water with flower food, and keep away from heat/direct sunlight.";
    } else if (normalized.contains("địa chỉ") || normalized.contains("map") || normalized.contains("address") || normalized.contains("ở đâu")) {
      reply = "Our main store is located at 456 Hai Ba Trung, District 1, Ho Chi Minh City. You can check the Map section for working hours and directions.";
    }

    return await sendMessage(reply, "store");
  }

  // ==========================================
  // STORE LOCATION APIs
  // ==========================================

  Future<List<StoreLocation>> getStoreLocations() async {
    if (isSupabaseInitialized) {
      try {
        final List<dynamic> data = await _supabase!.from('store_locations').select();
        return data.map((json) => StoreLocation.fromJson(json as Map<String, dynamic>)).toList();
      } catch (_) {
        return _mockLocations;
      }
    }
    return _mockLocations;
  }
}
