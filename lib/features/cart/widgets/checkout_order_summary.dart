import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';
import 'package:prm393/features/cart/providers/cart_provider.dart';

class CheckoutOrderSummary extends StatelessWidget {
  final CartProvider cartProvider;
  final String? errorMessage;

  const CheckoutOrderSummary({
    super.key,
    required this.cartProvider,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorMessage != null) ...[
          Text(errorMessage!, style: const TextStyle(color: Colors.redAccent)),
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
                ...cartProvider.items.map((item) {
                  final itemPrice =
                      item.product.promoPrice ?? item.product.price;
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
                _SummaryRow(
                  label: "Tạm tính",
                  value: formatVnd(cartProvider.subtotalAmount),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Phí giao hàng",
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                    Text(
                      cartProvider.shippingFee == 0.0
                          ? "Miễn phí"
                          : formatVnd(cartProvider.shippingFee),
                      style: TextStyle(
                        color: cartProvider.shippingFee == 0.0
                            ? Colors.green
                            : AppTheme.textPrimaryColor,
                        fontWeight: cartProvider.shippingFee == 0.0
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
                      formatVnd(cartProvider.totalAmount),
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
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor)),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
