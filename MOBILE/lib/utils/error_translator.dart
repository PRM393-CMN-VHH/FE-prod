import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/providers/toast_provider.dart';

class ErrorTranslator {
  static void showTopToast(BuildContext context, String message, {bool isError = true}) {
    Provider.of<ToastProvider>(context, listen: false).show(message, isError: isError);
  }

  static String userMessage(Object error) {
    var message = error.toString();
    var previous = '';
    while (previous != message) {
      previous = message;
      message = message
          .replaceFirst(RegExp(r'^Exception:\s*'), '')
          .replaceFirst(
            RegExp(r'^(GET|POST|PUT|DELETE) Request failed:\s*'),
            '',
          );
    }

    final lower = message.toLowerCase();
    if (lower.contains('timeoutexception') || lower.contains('timed out')) {
      return 'Hệ thống phản hồi quá lâu. Vui lòng thử lại sau.';
    }

    if (lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('cannot connect to backend') ||
        lower.contains('cannot reach backend') ||
        lower.contains('clientexception')) {
      return 'Không thể kết nối đến hệ thống. Vui lòng kiểm tra mạng hoặc thử lại sau.';
    }

    if (lower.contains('not logged in') ||
        lower.contains('not authenticated') ||
        lower.contains('unauthorized')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }

    if (lower.contains('email hoặc mật khẩu không đúng') ||
        lower.contains('email or password') ||
        lower.contains('invalid credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    }

    if (lower.contains('phone number is already in use')) {
      return 'Số điện thoại này đã được sử dụng.';
    }

    if (lower.contains('tài khoản này đã bị vô hiệu hóa')) {
      return 'Tài khoản của bạn đã bị vô hiệu hóa. Vui lòng liên hệ cửa hàng để được hỗ trợ.';
    }

    if (lower.contains('giỏ hàng trống')) {
      return 'Giỏ hàng của bạn đang trống.';
    }

    if (lower.contains('sản phẩm không có trong giỏ hàng')) {
      return 'Sản phẩm này không còn trong giỏ hàng.';
    }

    if (lower.contains('vượt quá tồn kho') ||
        lower.contains('chỉ còn') ||
        lower.contains('hết hàng')) {
      return message;
    }

    if (lower.contains('http error 400')) {
      return 'Thông tin gửi lên chưa hợp lệ. Vui lòng kiểm tra lại.';
    }
    if (lower.contains('http error 401') || lower.contains('http error 403')) {
      return 'Bạn không có quyền thực hiện thao tác này. Vui lòng đăng nhập lại.';
    }
    if (lower.contains('http error 404')) {
      return 'Không tìm thấy dữ liệu cần thao tác.';
    }
    if (lower.contains('http error 500')) {
      return 'Hệ thống đang gặp sự cố. Vui lòng thử lại sau.';
    }

    if (lower.contains('invalid') && lower.contains('response')) {
      return 'Dữ liệu từ hệ thống chưa đúng định dạng. Vui lòng thử lại sau.';
    }

    return message.isEmpty ? 'Đã có lỗi xảy ra. Vui lòng thử lại.' : message;
  }
}
