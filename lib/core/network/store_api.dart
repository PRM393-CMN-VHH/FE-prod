import 'package:prm393/features/stores/models/store_location.dart';
import 'package:prm393/core/network/api_client_base.dart';

/// Store locations and shop "about us" info.
mixin StoreApi on ApiClientBase {
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

  Future<List<StoreLocation>> getStoreLocations() async {
    try {
      final response = await request(ApiEndpoints.storeLocations);
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

  Future<Map<String, dynamic>> getAboutUs() async {
    try {
      final response = await request(ApiEndpoints.aboutUs);
      if (response is Map<String, dynamic>) {
        return response;
      }
    } catch (_) {}
    return {
      "shopName": "Tiệm Hoa Tươi Antigravity",
      "description": "Chuyên cung cấp các loại hoa tươi Đà Lạt, hoa nhập khẩu Ecuador, Hà Lan chất lượng cao, thiết kế bó hoa sang trọng."
    };
  }
}
