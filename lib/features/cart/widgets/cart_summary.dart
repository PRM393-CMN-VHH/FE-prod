import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/core/utils/currency_formatter.dart';

class CartSummary extends StatelessWidget {
  const CartSummary({
    super.key,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.onCheckout,
  });

  final double subtotal;
  final double shippingFee;
  final double total;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryRow(
              label: 'Tạm tính',
              value: formatVnd(subtotal),
              valueStyle: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Phí giao hàng',
              value: shippingFee == 0 ? 'Miễn phí' : formatVnd(shippingFee),
              valueStyle: TextStyle(
                color: shippingFee == 0
                    ? Colors.green
                    : AppTheme.textPrimaryColor,
                fontWeight: shippingFee == 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Tổng thanh toán',
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              value: formatVnd(total),
              valueStyle: textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onCheckout,
              child: const Text('Tiến hành thanh toán'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              labelStyle ?? const TextStyle(color: AppTheme.textSecondaryColor),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}
