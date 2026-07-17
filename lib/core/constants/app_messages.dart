/// Danh sách tập trung mọi thông báo/lỗi hiển thị cho người dùng.
/// Quy ước: KHÔNG hard-code text thông báo trong màn hình — luôn tham chiếu
/// enum này. Thông báo có tham số dùng placeholder `{}` và gọi `.format([...])`.
enum AppMessage {
  // ===== Auth =====
  loginSuccess("Đăng nhập thành công!"),
  registrationSuccess("Đăng ký thành công!"),
  otpTitle("Xác thực OTP"),
  otpSentToEmail("Mã OTP gồm 6 chữ số đã được gửi đến email của bạn."),
  otpIncomplete("Vui lòng nhập đủ 6 số OTP"),
  otpVerifyAndRegister("Xác thực & Đăng ký"),
  logoutTitle("Đăng xuất"),
  logoutConfirmMessage("Bạn có chắc muốn đăng xuất khỏi Tiệm Hoa Xinh?"),

  // ===== Validation (form) =====
  nameRequired("Vui lòng nhập họ tên"),
  emailRequired("Vui lòng nhập email"),
  emailInvalid("Email không hợp lệ"),
  phoneRequired("Vui lòng nhập số điện thoại"),
  addressRequired("Vui lòng nhập địa chỉ"),
  deliveryAddressRequired("Vui lòng nhập địa chỉ giao hàng"),
  recipientNameRequired("Vui lòng nhập tên người nhận"),
  passwordRequired("Vui lòng nhập mật khẩu"),
  passwordTooShort("Mật khẩu phải có ít nhất 6 ký tự"),
  fieldRequired("Bắt buộc"),
  priceInvalid("Giá không hợp lệ"),
  numberInvalid("Số không hợp lệ"),
  promoMustBeLower("Phải nhỏ hơn giá gốc"),

  // ===== Cart / Catalog =====
  addedToCart("Đã thêm {} x {} vào giỏ hàng"),
  addToCartFailed("Không thể thêm sản phẩm vào giỏ. Vui lòng thử lại."),
  removeFromCartFailed("Không thể xóa sản phẩm. Vui lòng thử lại."),
  updateQuantityFailed("Không thể cập nhật số lượng. Vui lòng thử lại."),
  stockLimitReached("Không thể vượt quá số lượng tồn kho."),
  cartEmptyTitle("Giỏ hàng đang trống"),
  cartEmptyHint("Hãy chọn hoa bạn thích để thêm vào giỏ"),

  // ===== Checkout / Payment =====
  vnpayCreateFailed("Không thể tạo đơn thanh toán VNPAY. Vui lòng thử lại."),
  vnpayOpenFailed("Không thể mở thanh toán VNPAY. Vui lòng thử lại."),
  orderCreateFailed("Không thể tạo đơn hàng. Vui lòng thử lại."),
  orderPlacedTitle("Đặt hàng thành công!"),
  orderPlacedBody(
    "Đơn hàng của bạn đã được tạo. Thông báo xác nhận đã được gửi vào mục Tin của bạn.",
  ),
  paymentSuccessTitle("Thanh toán thành công!"),
  vnpayPaymentDone("Giao dịch VNPay cho đơn hàng {} đã hoàn tất."),
  paymentFailed("Thanh toán thất bại: {}"),
  paymentCancelledFallback("Đã hủy"),
  backToHome("Về trang chủ"),

  // ===== Profile =====
  profileUpdated("Đã cập nhật hồ sơ"),
  profileUpdateFailed("Không thể cập nhật hồ sơ"),

  // ===== Stores / Map =====
  mapOpenFailed("Không thể mở ứng dụng bản đồ"),

  // ===== Admin: thao tác =====
  adminProductAdded("Đã thêm sản phẩm mới"),
  adminProductUpdated("Đã cập nhật sản phẩm"),
  adminProductDeleted("Đã xóa \"{}\""),
  adminOrderStatusUpdated("Đã cập nhật trạng thái đơn #{}"),
  adminRoleChanged("Đã đổi quyền thành {}"),
  adminUserLocked("Đã khóa tài khoản"),
  adminUserUnlocked("Đã mở khóa tài khoản"),

  // ===== Admin: dialog xác nhận =====
  confirmDefault("Xác nhận"),
  cancelAction("Hủy"),
  adminCancelOrderTitle("Hủy đơn hàng #{}?"),
  adminCancelOrderMessage(
    "Đơn hàng sẽ được đánh dấu là đã hủy và không thể hoàn tác.",
  ),
  adminCancelOrderConfirm("Hủy đơn"),
  adminChangeStatusTitle("Đổi trạng thái đơn hàng"),
  adminDeleteProductTitle("Xóa sản phẩm?"),
  adminDeleteProductMessage(
    "\"{}\" sẽ bị xóa vĩnh viễn khỏi cửa hàng. Hành động này không thể hoàn tác.",
  ),
  adminDeleteConfirm("Xóa"),
  adminLockUserTitle("Khóa tài khoản?"),
  adminLockUserMessage(
    "{} sẽ không thể đăng nhập cho đến khi được mở khóa lại.",
  ),
  adminLockConfirm("Khóa"),
  adminChangeRoleTitle("Đổi quyền thành {}?"),
  adminChangeRoleMessage("{} sẽ có quyền truy cập của vai trò {}."),

  // ===== Admin: trạng thái rỗng =====
  adminEmptyOrders("Không có đơn hàng phù hợp"),
  adminEmptyProducts("Không tìm thấy sản phẩm nào"),
  adminEmptyUsers("Không tìm thấy người dùng nào"),
  adminEmptyConversations("Chưa có cuộc trò chuyện nào từ khách hàng");

  final String text;
  const AppMessage(this.text);

  /// Thay lần lượt các placeholder `{}` bằng [args].
  /// Ví dụ: AppMessage.addedToCart.format([2, "Hoa hồng"]).
  String format(List<Object?> args) {
    var result = text;
    for (final arg in args) {
      result = result.replaceFirst('{}', '$arg');
    }
    return result;
  }
}
