String orderStatusLabel(String status) {
  switch (status.trim().toUpperCase()) {
    case 'PENDING':
    case 'PENDING CONFIRMATION':
      return 'Chờ xác nhận';
    case 'CONFIRM':
    case 'CONFIRMED':
      return 'Đã xác nhận';
    case 'PROCESSING':
      return 'Đang xử lý';
    case 'SHIPPED':
    case 'SHIPPING':
      return 'Đang giao';
    case 'DELIVERED':
      return 'Đã giao';
    case 'CANCELLED':
    case 'CANCELED':
      return 'Đã hủy';
    case 'PAID (VNPAY)':
      return 'Đã thanh toán VNPay';
    default:
      return status.isEmpty ? '-' : status;
  }
}

String paymentStatusLabel(String status) {
  switch (status.trim().toUpperCase()) {
    case 'PAID':
      return 'Đã thanh toán';
    case 'UNPAID':
      return 'Chưa thanh toán';
    case 'PENDING':
      return 'Đang chờ';
    case 'FAILED':
      return 'Thất bại';
    case 'CANCELLED':
    case 'CANCELED':
      return 'Đã hủy';
    default:
      return status.isEmpty ? '' : status;
  }
}
