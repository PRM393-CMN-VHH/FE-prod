import 'package:prm393/features/catalog/models/product.dart';
import 'package:prm393/features/auth/models/user.dart';
import 'package:prm393/core/network/api_client_base.dart';

/// Admin dashboard: orders, products, users management.
mixin AdminApi on ApiClientBase {
  Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    final response = await request(
      ApiEndpoints.adminLogin,
      body: {'email': email, 'password': password},
    );
    if (response is Map<String, dynamic>) return response;
    throw Exception("Invalid admin login response from server");
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await request(ApiEndpoints.adminDashboard);
    if (response is Map<String, dynamic>) return response;
    throw Exception("Invalid admin dashboard response from server");
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
    final response = await request(ApiEndpoints.adminOrders, query: query);
    if (response is Map<String, dynamic>) return response;
    throw Exception("Invalid admin orders response from server");
  }

  Future<Map<String, dynamic>> updateAdminOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final response = await request(
      ApiEndpoints.adminOrderUpdateStatus,
      query: {'orderId': orderId.toString(), 'status': status},
    );
    if (response is Map<String, dynamic>) return response;
    throw Exception("Invalid update order status response from server");
  }

  Future<Map<String, dynamic>> getAdminProducts({
    int pageNo = 1,
    String? keyword,
  }) async {
    final query = <String, String>{'pageNo': pageNo.toString()};
    if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;
    final response = await request(ApiEndpoints.adminProducts, query: query);
    if (response is Map<String, dynamic>) return response;
    throw Exception("Invalid admin products response from server");
  }

  Future<Product> addAdminProduct(Product product) async {
    final response = await request(
      ApiEndpoints.adminProductAdd,
      body: product.toBackendJson(),
    );
    if (response is Map<String, dynamic>) return Product.fromJson(response);
    throw Exception("Invalid add product response from server");
  }

  Future<Product> editAdminProduct(Product product) async {
    final response = await request(
      ApiEndpoints.adminProductEdit,
      body: product.toBackendJson(),
    );
    if (response is Map<String, dynamic>) return Product.fromJson(response);
    throw Exception("Invalid edit product response from server");
  }

  Future<void> deleteAdminProduct(int productId) async {
    await request(
      ApiEndpoints.adminProductDelete,
      params: {'productId': productId},
    );
  }

  Future<Map<String, dynamic>> getAdminUsers({
    int pageNo = 1,
    String? search,
  }) async {
    final query = <String, String>{'pageNo': pageNo.toString()};
    if (search != null && search.isNotEmpty) query['search'] = search;
    final response = await request(ApiEndpoints.adminUsers, query: query);
    if (response is Map<String, dynamic>) return response;
    throw Exception("Invalid admin users response from server");
  }

  Future<UserModel> activateAdminUser(int userId) async {
    final response = await request(
      ApiEndpoints.adminUserActivate,
      params: {'userId': userId},
    );
    if (response is Map<String, dynamic>) return UserModel.fromJson(response);
    throw Exception("Invalid activate user response from server");
  }

  Future<UserModel> deactivateAdminUser(int userId) async {
    final response = await request(
      ApiEndpoints.adminUserDeactivate,
      params: {'userId': userId},
    );
    if (response is Map<String, dynamic>) return UserModel.fromJson(response);
    throw Exception("Invalid deactivate user response from server");
  }

  Future<UserModel> updateAdminUserRole({
    required int userId,
    required int roleId,
  }) async {
    final response = await request(
      ApiEndpoints.adminUserUpdateRole,
      params: {'userId': userId},
      query: {'roleId': roleId.toString()},
    );
    if (response is Map<String, dynamic>) return UserModel.fromJson(response);
    throw Exception("Invalid update user role response from server");
  }
}
