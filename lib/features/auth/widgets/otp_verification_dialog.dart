import 'package:flutter/material.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/auth/providers/auth_provider.dart';

Future<void> showOtpVerificationDialog(
  BuildContext context, {
  required AuthProvider authProvider,
  required String email,
  required String password,
  required String name,
  required String phone,
  required String address,
}) {
  final otpController = TextEditingController();
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Xác thực OTP"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Mã OTP gồm 6 chữ số đã được gửi đến email của bạn."),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "Nhập OTP",
                prefixIcon: Icon(Icons.security),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final otp = otpController.text.trim();
              if (otp.length != 6) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text("Vui lòng nhập đủ 6 số OTP")),
                );
                return;
              }

              Navigator.pop(dialogContext);

              final success = await authProvider.signUp(
                email: email,
                password: password,
                name: name,
                phone: phone,
                address: address,
                otp: otp,
              );

              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Registration successful!"),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              }
            },
            child: const Text("Xác thực & Đăng ký"),
          ),
        ],
      );
    },
  );
}
