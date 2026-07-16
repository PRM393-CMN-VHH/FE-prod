import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';

class OrderInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const OrderInfoTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
