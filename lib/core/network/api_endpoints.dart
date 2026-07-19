/// Single source of truth for every backend endpoint: HTTP method + path.
///
/// Paths are relative to `ApiClientBase.backendBaseUrl` and may contain
/// `{param}` placeholders, filled in via `ApiClientBase.request(endpoint,
/// params: {...})`. Query strings and request bodies are passed separately
/// at the call site — only the fixed method+path shape lives here.
library;

enum ApiVerb { get, post, put, delete }

class Endpoint {
  final ApiVerb method;
  final String path;
  const Endpoint(this.method, this.path);
}

class ApiEndpoints {
  ApiEndpoints._();

  // ---- Auth ----
  static const signIn = Endpoint(ApiVerb.post, '/login');
  static const signUp = Endpoint(ApiVerb.post, '/register');
  static const requestOtp = Endpoint(ApiVerb.post, '/register/request-otp');
  static const signOut = Endpoint(ApiVerb.get, '/logout');
  static const currentUser = Endpoint(ApiVerb.get, '/api/users/me');
  static const profile = Endpoint(ApiVerb.get, '/profile');
  static const profileUpdate = Endpoint(ApiVerb.post, '/profile/update');

  // ---- Catalog ----
  static const products = Endpoint(ApiVerb.get, '/product/all-product');
  static const productsSearch = Endpoint(ApiVerb.post, '/product/search');
  static const categoryProducts =
      Endpoint(ApiVerb.get, '/product/category/{categoryId}');
  static const productDetails = Endpoint(ApiVerb.get, '/products/{productId}');
  static const productSuggest =
      Endpoint(ApiVerb.get, '/api/products/suggest');
  static const adminCategories =
      Endpoint(ApiVerb.get, '/admin/product/categories');

  // ---- Cart ----
  static const cart = Endpoint(ApiVerb.get, '/cart');
  static const cartAdd = Endpoint(ApiVerb.post, '/cart/add');
  static const cartUpdate = Endpoint(ApiVerb.post, '/cart/update');
  static const cartRemove = Endpoint(ApiVerb.post, '/cart/remove');
  static const cartCheckout = Endpoint(ApiVerb.get, '/cart/checkout');
  static const placeOrder = Endpoint(ApiVerb.post, '/cart/place-order');

  // ---- Orders & VNPay ----
  static const orders = Endpoint(ApiVerb.get, '/order/my-orders');
  static const orderDetail = Endpoint(ApiVerb.get, '/order/detail/{orderId}');
  static const orderPay = Endpoint(ApiVerb.post, '/order/pay/{orderId}');
  static const orderCancel = Endpoint(ApiVerb.post, '/order/cancel/{orderId}');
  static const transactionHistory =
      Endpoint(ApiVerb.get, '/transaction/history');
  static const paymentCreate = Endpoint(ApiVerb.get, '/payment/create');

  // ---- Admin ----
  static const adminLogin = Endpoint(ApiVerb.post, '/admin/login');
  static const adminDashboard = Endpoint(ApiVerb.get, '/admin/dashboard');
  static const adminOrders = Endpoint(ApiVerb.get, '/admin/orders');
  static const adminOrderUpdateStatus =
      Endpoint(ApiVerb.post, '/admin/orders/update-status');
  static const adminProducts = Endpoint(ApiVerb.get, '/admin/products');
  static const adminProductAdd = Endpoint(ApiVerb.post, '/admin/products/add');
  static const adminProductEdit =
      Endpoint(ApiVerb.post, '/admin/products/edit');
  static const adminProductDelete =
      Endpoint(ApiVerb.delete, '/admin/products/delete/{productId}');
  static const adminUsers = Endpoint(ApiVerb.get, '/admin/users');
  static const adminUserActivate =
      Endpoint(ApiVerb.post, '/admin/users/activate/{userId}');
  static const adminUserDeactivate =
      Endpoint(ApiVerb.post, '/admin/users/deactivate/{userId}');
  static const adminUserUpdateRole =
      Endpoint(ApiVerb.post, '/admin/users/update-role/{userId}');

  // ---- Notifications ----
  static const notifications = Endpoint(ApiVerb.get, '/api/notifications');
  static const notificationRead =
      Endpoint(ApiVerb.post, '/api/notifications/{id}/read');
  static const notificationsReadAll =
      Endpoint(ApiVerb.post, '/api/notifications/read-all');

  // ---- Chat (REST; live updates go over the ws_chat WebSocket) ----
  static const chatConversation =
      Endpoint(ApiVerb.get, '/api/chat/conversation');
  static const chatConversations =
      Endpoint(ApiVerb.get, '/api/chat/conversations');
  static const chatConversationMessages = Endpoint(
    ApiVerb.get,
    '/api/chat/conversations/{conversationId}/messages',
  );
  static const chatSendConversationMessage = Endpoint(
    ApiVerb.post,
    '/api/chat/conversations/{conversationId}/messages',
  );
  static const chatSendMyMessage =
      Endpoint(ApiVerb.post, '/api/chat/messages');
  static const chatMarkRead = Endpoint(
    ApiVerb.post,
    '/api/chat/conversations/{conversationId}/read',
  );
  static const chatUnreadCount =
      Endpoint(ApiVerb.get, '/api/chat/unread-count');
  static const wsChat = Endpoint(ApiVerb.get, '/ws/chat');

  // ---- Store ----
  static const storeLocations =
      Endpoint(ApiVerb.get, '/api/store-locations');
  static const aboutUs = Endpoint(ApiVerb.get, '/about-us');
}
