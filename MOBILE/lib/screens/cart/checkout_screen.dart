import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/providers/auth_provider.dart';
import 'package:prm393/providers/cart_provider.dart';
import 'package:prm393/providers/order_provider.dart';
import 'package:prm393/theme/app_theme.dart';
import 'package:prm393/screens/cart/vnpay_payment_screen.dart';

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
      // 1. Generate local/Supabase VNPAY payment URL
      final txnRef = DateTime.now().millisecondsSinceEpoch.toString();
      final paymentUrl = await orderProv.getVnpayUrl(
        amount: cartProv.totalAmount,
        orderId: txnRef,
      );

      if (paymentUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProv.errorMessage ?? "Failed to initiate VNPAY payment"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // 2. Open simulated VNPAY portal
      if (mounted) {
        final String? resultCode = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => VnpayPaymentScreen(
              amount: cartProv.totalAmount,
              orderId: txnRef,
              paymentUrl: paymentUrl!,
            ),
          ),
        );

        if (resultCode == '00') {
          // VNPAY Success, create order with "Paid (VNPAY)" status
          _createFinalOrder("Paid (VNPAY)");
        } else {
          // Cancelled or failed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("VNPAY transaction was cancelled or failed"),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      }
    } else {
      // Standard COD/Bank transfer flow
      _createFinalOrder("Confirmed");
    }
  }

  void _createFinalOrder(String orderStatus) async {
    final cartProv = Provider.of<CartProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);

    final success = await orderProv.placeOrder(
      recipientName: _nameController.text.trim(),
      recipientPhone: _phoneController.text.trim(),
      shippingAddress: _addressController.text.trim(),
      paymentMethod: _paymentMethod,
      totalAmount: cartProv.totalAmount,
      cartItems: cartProv.items,
      status: orderStatus,
    ) != null;

    if (success && mounted) {
      // Clear the local cart
      await cartProv.clearCart();

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Order Placed!"),
          content: Text(
            orderStatus == "Paid (VNPAY)"
                ? "Your payment via VNPAY was successful! We have sent a confirmation alert to your Notifications inbox."
                : "Your purchase was successful. We have sent a confirmation details alert to your Notifications inbox."
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Pop back to home screen
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text("Back to Home"),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProv.errorMessage ?? "Failed to create order"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProv = Provider.of<CartProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
      ),
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
                    Text("Order Summary", style: textTheme.titleLarge),
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
                              final itemPrice = item.product.promoPrice ?? item.product.price;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${item.product.name} (x${item.quantity})",
                                        style: textTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      "\$${(itemPrice * item.quantity).toStringAsFixed(2)}",
                                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Items Subtotal", style: TextStyle(color: AppTheme.textSecondaryColor)),
                                Text("\$${cartProv.subtotalAmount.toStringAsFixed(2)}", style: textTheme.bodyMedium),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Shipping Fee", style: TextStyle(color: AppTheme.textSecondaryColor)),
                                Text(
                                  cartProv.shippingFee == 0.0 ? "FREE" : "\$${cartProv.shippingFee.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: cartProv.shippingFee == 0.0 ? Colors.green : AppTheme.textPrimaryColor,
                                    fontWeight: cartProv.shippingFee == 0.0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  "\$${cartProv.totalAmount.toStringAsFixed(2)}",
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
                    Text("Delivery Information", style: textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Recipient Name",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter recipient name";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Contact Phone",
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter contact number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Full Shipping Address",
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter shipping address";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: "Delivery Notes (Optional)",
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payment Method section
                    Text("Payment Method", style: textTheme.titleLarge),
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
                            title: const Text("Cash on Delivery (COD)"),
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
                            title: const Text("Bank Transfer"),
                            value: 'Bank Transfer',
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
                            title: const Text("Mock E-Wallet Pay"),
                            value: 'E-Wallet',
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
                            title: const Text("Pay via VNPAY (ATM/Bank)"),
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

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _placeOrder,
                      child: const Text("Confirm & Place Order"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
