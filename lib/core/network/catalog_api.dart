import 'package:prm393/features/catalog/models/category.dart';
import 'package:prm393/features/catalog/models/product.dart';
import 'package:prm393/core/network/api_client_base.dart';

/// Product & category browsing/search.
mixin CatalogApi on ApiClientBase {
  Future<List<Category>> getCategories() async {
    final response = await request(ApiEndpoints.adminCategories);
    if (response is List) {
      return response
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Invalid categories response from server");
  }

  Future<List<Product>> getProducts() async {
    final response = await request(ApiEndpoints.products);
    if (response is List) {
      return response
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Invalid products response from server");
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final response = await request(
      ApiEndpoints.categoryProducts,
      params: {'categoryId': categoryId},
    );
    if (response is Map && response['products'] is List) {
      return (response['products'] as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Invalid category products response from server");
  }

  Future<Product> getProductDetail(int productId) async {
    final response = await request(
      ApiEndpoints.productDetails,
      params: {'productId': productId},
    );
    if (response is Map && response['product'] is Map) {
      return Product.fromJson(response['product'] as Map<String, dynamic>);
    }
    throw Exception("Invalid product detail response from server");
  }

  Future<List<Product>> getRelatedProducts(int productId) async {
    final response = await request(
      ApiEndpoints.productDetails,
      params: {'productId': productId},
    );
    if (response is Map && response['relatedProducts'] is List) {
      return (response['relatedProducts'] as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Invalid related products response from server");
  }

  Future<List<Product>> searchProducts(String keyword) async {
    final response = await request(
      ApiEndpoints.productsSearch,
      query: {'keyword': keyword},
    );
    if (response is List) {
      return response
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Invalid search response from server");
  }

  Future<List<Map<String, dynamic>>> suggestProducts(String keyword) async {
    final response = await request(
      ApiEndpoints.productSuggest,
      query: {'keyword': keyword},
    );
    if (response is List) {
      return response
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();
    }
    throw Exception("Invalid product suggestions response from server");
  }
}
