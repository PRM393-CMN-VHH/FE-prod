class StatusTranslator {
  static String orderStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'SHIPPED':
        return 'Đang giao';
      case 'DELIVERED':
        return 'Đã giao';
      case 'COMPLETED':
        return 'Đã nhận hàng';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        if (status.isEmpty) return status;
        return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }

  static String paymentStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return 'Đã thanh toán';
      case 'UNPAID':
        return 'Chưa thanh toán';
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'FAILED':
        return 'Thất bại';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        if (status.isEmpty) return status;
        return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }
}
