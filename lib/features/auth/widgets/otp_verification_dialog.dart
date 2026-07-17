import 'package:flutter/material.dart';
import 'package:prm393/core/constants/app_messages.dart';
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
        title: Text(AppMessage.otpTitle.text),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppMessage.otpSentToEmail.text),
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
            child: Text(AppMessage.cancelAction.text),
          ),
          ElevatedButton(
            onPressed: () async {
              final otp = otpController.text.trim();
              if (otp.length != 6) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(AppMessage.otpIncomplete.text)),
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
                  SnackBar(
                    content: Text(AppMessage.registrationSuccess.text),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              }
            },
            child: Text(AppMessage.otpVerifyAndRegister.text),
          ),
        ],
      );
    },
  );
}
