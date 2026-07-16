import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        const Icon(
          Icons.local_florist,
          size: 80,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          "Tiệm Hoa Xinh",
          textAlign: TextAlign.center,
          style: textTheme.headlineLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontFamily: 'serif',
          ),
        ),
        Text(
          "Hoa tươi giao mỗi ngày",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}
