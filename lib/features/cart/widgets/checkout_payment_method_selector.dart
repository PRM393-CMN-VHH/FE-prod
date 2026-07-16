import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';

class CheckoutPaymentMethodSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const CheckoutPaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Phương thức thanh toán", style: textTheme.titleLarge),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: value,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            child: const Column(
              children: [
                RadioListTile<String>(
                  title: Text("Thanh toán khi nhận hàng (COD)"),
                  value: 'COD',
                  activeColor: AppTheme.primaryColor,
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                RadioListTile<String>(
                  title: Text("Thanh toán qua VNPAY (ATM/Ngân hàng)"),
                  value: 'VNPAY',
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
