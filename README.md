# Tiệm Hoa Xinh - Flutter App (FE-prod)

Ứng dụng mobile bán hoa, viết bằng Flutter. Backend tương ứng nằm ở repo riêng: `flower-management` (Spring Boot).

## 1. Yêu cầu môi trường

- Flutter SDK (kênh stable) — kiểm tra bằng `flutter doctor`
- Android Studio (kèm Android SDK) để chạy trên Android, hoặc Xcode để chạy trên iOS/macOS
- Backend `flower-management` phải **chạy trước** vì app không có chế độ offline đầy đủ (đăng nhập, giỏ hàng, chat... đều gọi API)

## 2. Chạy backend trước

```bash
cd ../flower-management
./mvnw spring-boot:run
```

Backend mặc định chạy ở cổng `3636`, cần Postgres và Redis đang chạy local (xem `src/main/resources/application.properties` để biết thông tin kết nối DB/Redis/mail). Dữ liệu mẫu (tài khoản admin/user, sản phẩm...) được `DataInitializer` tự seed lần chạy đầu tiên nếu DB rỗng.

## 3. Cấu hình địa chỉ backend cho Flutter

Flutter app trỏ tới backend qua `backendBaseUrl` trong [lib/core/network/api_service.dart](lib/core/network/api_service.dart):

- Chạy trên web/Chrome hoặc simulator/emulator cùng máy: mặc định dùng `http://localhost:3636`
- Chạy trên **thiết bị thật** (điện thoại thật qua USB/WiFi): sửa IP `172.20.10.6` trong file trên thành địa chỉ IP LAN thực tế của máy đang chạy backend (dùng `ipconfig getifaddr en0` trên macOS để lấy IP), rồi hot-restart lại app

```dart
static String get backendBaseUrl {
  if (kIsWeb) {
    return "http://localhost:3636";
  }
  return "http://172.20.10.6:3636"; // <-- đổi IP LAN của máy chạy backend ở đây
}
```

> Lưu ý: emulator Android không dùng được `localhost` để trỏ về máy host — dùng `10.0.2.2` thay cho `localhost`, hoặc dùng IP LAN như trên.

## 4. Cài dependency và chạy app

```bash
flutter pub get
flutter run
```

Chọn thiết bị đích khi được hỏi (hoặc dùng `flutter run -d chrome`, `flutter run -d <device-id>`).

## 5. Kiểm tra nhanh

```bash
flutter analyze   # kiểm tra lỗi/warning
flutter test      # chạy unit/widget test
```

## 6. Tính năng cần lưu ý khi test

- **Đăng nhập/đăng ký**: dùng session cookie, backend cấp OTP đăng ký qua email SMTP đã cấu hình
- **Chat realtime (WebSocket)**: kết nối tới `ws://<backendBaseUrl>/ws/chat`, chỉ hoạt động trên mobile/desktop (không hỗ trợ trên web do trình duyệt không cho set custom header khi handshake) — trên web, chat vẫn dùng được nhưng qua REST (gửi tin nhắn được, không nhận realtime tự động, cần refresh)
- **Tài khoản mẫu** (do `DataInitializer` seed): `admin@gmail.com` / `12345678` (admin), `user@gmail.com` / `12345678` (khách hàng)

## 7. Cấu trúc thư mục

```
lib/
  app/        # khởi tạo app, provider tree, auth gate
  core/       # network/api, theme, constants, utils dùng chung
  features/   # từng tính năng (auth, cart, catalog, chat, orders, admin, ...)
    <feature>/
      models/
      providers/
      screens/
      widgets/
```

## 8. Build release (tuỳ chọn)

```bash
flutter build apk        # Android
flutter build ios        # iOS (cần macOS + Xcode)
```

Nhớ đổi `backendBaseUrl` sang domain backend thật (không phải localhost/IP LAN) trước khi build bản release phân phối cho người dùng thật.
