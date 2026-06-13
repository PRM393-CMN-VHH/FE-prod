import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/providers/auth_provider.dart';
import 'package:prm393/providers/cart_provider.dart';
import 'package:prm393/providers/order_provider.dart';
import 'package:prm393/services/api_service.dart';
import 'package:prm393/theme/app_theme.dart';
import 'package:prm393/screens/cart/vnpay_payment_screen.dart';
import 'package:prm393/utils/currency_formatter.dart';
import 'package:prm393/utils/error_translator.dart';
import 'package:prm393/utils/payment_navigation_signal.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentMethod = 'COD';
  String? _checkoutError;

  @override
  void initState() {
    super.initState();
    // Prefill form from current authenticated user info
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    if (authProv.user != null) {
      _nameController.text = authProv.user!.name;
      _phoneController.text = authProv.user!.phone;
      _addressController.text = authProv.user!.address;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCheckoutSummary());
  }

  Future<void> _loadCheckoutSummary() async {
    try {
      final summary = await ApiService().getCheckoutSummary();
      final account = summary['account'];
      if (!mounted || account is! Map) return;
      setState(() {
        _nameController.text = account['fullName'] ?? _nameController.text;
        _phoneController.text = account['phoneNumber'] ?? _phoneController.text;
        _addressController.text = account['address'] ?? _addressController.text;
        _checkoutError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkoutError = ErrorTranslator.userMessage(e);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartProv = Provider.of<CartProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);

    if (_paymentMethod == 'VNPAY') {
      final order = await orderProv.placeOrder(
        recipientName: _nameController.text.trim(),
        recipientPhone: _phoneController.text.trim(),
        shippingAddress: _addressController.text.trim(),
        paymentMethod: _paymentMethod,
        totalAmount: cartProv.totalAmount,
        cartItems: cartProv.items,
        status: "Pending",
      );

      if (order == null) {
        if (mounted) {
          ErrorTranslator.showTopToast(
            context,
            orderProv.errorMessage ??
                "Không thể tạo đơn thanh toán VNPAY. Vui lòng thử lại.",
          );
        }
        return;
      }

      final paymentUrl =
          order.paymentUrl ??
          await orderProv.getVnpayUrl(
            amount: order.totalAmount,
            orderId: order.id.toString(),
          );

      if (paymentUrl == null && mounted) {
        ErrorTranslator.showTopToast(
          context,
          orderProv.errorMessage ??
              "Không thể mở thanh toán VNPAY. Vui lòng thử lại.",
        );
        return;
      }

      if (mounted) {
        final checkoutContext = context;
        final checkoutNavigator = Navigator.of(checkoutContext);

        Navigator.push(
          checkoutContext,
          MaterialPageRoute(
            builder: (_) => VnpayPaymentScreen(
              paymentUrl: paymentUrl!,
              onPaymentSuccess: (result) async {
                checkoutNavigator.pop(); // Đóng WebView
                await cartProv.clearCart();
                await orderProv.loadTransactionHistory();
                requestPaidOrdersView();
                if (mounted) {
                  showDialog(
                    context: checkoutContext,
                    barrierDismissible: false,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Thanh toán thành công!"),
                      content: Text(
                        "Giao dịch VNPay cho đơn hàng ${order.id} đã hoàn tất.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => checkoutNavigator.popUntil(
                            (route) => route.isFirst,
                          ),
                          child: const Text("Về trang chủ"),
                        ),
                      ],
                    ),
                  );
                }
              },
              onPaymentFail: (error) {
                checkoutNavigator.pop(); // Đóng WebView
                if (mounted) {
                  ErrorTranslator.showTopToast(
                    context,
                    "Thanh toán thất bại: ${error['message'] ?? 'Đã hủy'}",
                  );
                }
              },
            ),
          ),
        );
      }
    } else {
      // Standard COD/Bank transfer flow
      _createFinalOrder("Confirmed");
    }
  }

  void _createFinalOrder(String orderStatus) async {
    final cartProv = Provider.of<CartProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);

    final success =
        await orderProv.placeOrder(
          recipientName: _nameController.text.trim(),
          recipientPhone: _phoneController.text.trim(),
          shippingAddress: _addressController.text.trim(),
          paymentMethod: _paymentMethod,
          totalAmount: cartProv.totalAmount,
          cartItems: cartProv.items,
          status: orderStatus,
        ) !=
        null;

    if (success && mounted) {
      // Clear the local cart
      await cartProv.clearCart();

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Đặt hàng thành công!"),
          content: Text(
            orderStatus == "Paid (VNPAY)"
                ? "Thanh toán qua VNPAY thành công! Chúng tôi đã gửi thông báo xác nhận đến hộp thư của bạn."
                : "Đặt hàng thành công. Chúng tôi đã gửi thông báo chi tiết đến hộp thư của bạn.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Pop back to home screen
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text("Về trang chủ"),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ErrorTranslator.showTopToast(
        context,
        orderProv.errorMessage ?? "Không thể tạo đơn hàng. Vui lòng thử lại.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProv = Provider.of<CartProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán")),
      body: orderProv.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Order Summary section
                    if (_checkoutError != null) ...[
                      Text(
                        _checkoutError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text("Tóm tắt đơn hàng", style: textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ...cartProv.items.map((item) {
                              final itemPrice = item.product.hasDiscount
                                  ? item.product.promoPrice!
                                  : item.product.price;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${item.product.name} (x${item.quantity})",
                                        style: textTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      formatVnd(itemPrice * item.quantity),
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Tạm tính",
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                Text(
                                  formatVnd(cartProv.subtotalAmount),
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Phí giao hàng",
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                Text(
                                  cartProv.shippingFee == 0.0
                                      ? "Miễn phí"
                                      : formatVnd(cartProv.shippingFee),
                                  style: TextStyle(
                                    color: cartProv.shippingFee == 0.0
                                        ? Colors.green
                                        : AppTheme.textPrimaryColor,
                                    fontWeight: cartProv.shippingFee == 0.0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Tổng cộng",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  formatVnd(cartProv.totalAmount),
                                  style: textTheme.titleMedium?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Delivery Details section
                    Text("Thông tin giao hàng", style: textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Người nhận",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Vui lòng nhập tên người nhận";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Số điện thoại",
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Vui lòng nhập số điện thoại";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Địa chỉ giao hàng",
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Vui lòng nhập địa chỉ giao hàng";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: "Ghi chú giao hàng (không bắt buộc)",
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payment Method section
                    Text("Phương thức thanh toán", style: textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text("Thanh toán khi nhận hàng (COD)"),
                            value: 'COD',
                            groupValue: _paymentMethod,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (val) {
                              setState(() {
                                _paymentMethod = val!;
                              });
                            },
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          RadioListTile<String>(
                            title: const Text(
                              "Thanh toán qua VNPAY (ATM/Ngân hàng)",
                            ),
                            value: 'VNPAY',
                            groupValue: _paymentMethod,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (val) {
                              setState(() {
                                _paymentMethod = val!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    if (orderProv.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        ErrorTranslator.userMessage(orderProv.errorMessage!),
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: orderProv.isLoading ? null : _placeOrder,
                      child: orderProv.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Xác nhận đặt hàng"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
