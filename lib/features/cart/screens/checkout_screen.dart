import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/features/auth/providers/auth_provider.dart';
import 'package:prm393/features/cart/providers/cart_provider.dart';
import 'package:prm393/features/orders/providers/order_provider.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/cart/screens/vnpay_payment_screen.dart';
import 'package:prm393/features/cart/widgets/checkout_order_summary.dart';
import 'package:prm393/features/cart/widgets/checkout_delivery_form.dart';
import 'package:prm393/features/cart/widgets/checkout_payment_method_selector.dart';
import 'package:prm393/core/utils/error_translator.dart';
import 'package:prm393/core/utils/payment_navigation_signal.dart';

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
      if (!context.mounted) return;
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

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
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

      if (!mounted) return;
      if (order == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              orderProv.errorMessage ??
                  "Không thể tạo đơn thanh toán VNPAY. Vui lòng thử lại.",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final paymentUrl =
          order.paymentUrl ??
          await orderProv.getVnpayUrl(
            amount: order.totalAmount,
            orderId: order.id.toString(),
          );

      if (!mounted) return;
      if (paymentUrl == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              orderProv.errorMessage ??
                  "Không thể mở thanh toán VNPAY. Vui lòng thử lại.",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      navigator.push(
        MaterialPageRoute(
          builder: (_) => VnpayPaymentScreen(
            paymentUrl: paymentUrl,
            onPaymentSuccess: (result) async {
              navigator.pop();
              await cartProv.clearCart();
              await orderProv.loadTransactionHistory();
              requestPaidOrdersView();
              if (!navigator.mounted) return;
              showDialog(
                context: navigator.context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: const Text("Thanh toán thành công!"),
                  content: Text(
                    "Giao dịch VNPay cho đơn hàng ${order.id} đã hoàn tất.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          navigator.popUntil((route) => route.isFirst),
                      child: const Text("Về trang chủ"),
                    ),
                  ],
                ),
              );
            },
            onPaymentFail: (error) {
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    "Thanh toán thất bại: ${error['message'] ?? 'Đã hủy'}",
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Standard COD/Bank transfer flow
      _createFinalOrder("Confirmed");
    }
  }

  void _createFinalOrder(String orderStatus) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
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
      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: navigator.context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Order Placed!"),
          content: Text(
            orderStatus == "Paid (VNPAY)"
                ? "Your payment via VNPAY was successful! We have sent a confirmation alert to your Notifications inbox."
                : "Your purchase was successful. We have sent a confirmation details alert to your Notifications inbox.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Pop back to home screen
                navigator.popUntil((route) => route.isFirst);
              },
              child: const Text("Back to Home"),
            ),
          ],
        ),
      );
    } else if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            orderProv.errorMessage ??
                "Không thể tạo đơn hàng. Vui lòng thử lại.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProv = Provider.of<CartProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);

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
                    CheckoutOrderSummary(
                      cartProvider: cartProv,
                      errorMessage: _checkoutError,
                    ),
                    const SizedBox(height: 24),
                    CheckoutDeliveryForm(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      addressController: _addressController,
                      notesController: _notesController,
                    ),
                    const SizedBox(height: 24),
                    CheckoutPaymentMethodSelector(
                      value: _paymentMethod,
                      onChanged: (value) =>
                          setState(() => _paymentMethod = value),
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
