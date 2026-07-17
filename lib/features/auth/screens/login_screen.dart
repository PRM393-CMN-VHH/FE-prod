import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/core/constants/app_messages.dart';
import 'package:prm393/features/auth/providers/auth_provider.dart';
import 'package:prm393/features/auth/widgets/inline_auth_error.dart';
import 'package:prm393/features/auth/widgets/login_header.dart';
import 'package:prm393/features/auth/widgets/otp_verification_dialog.dart';
import 'package:prm393/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Fields controller
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  void _clearBackendError() {
    Provider.of<AuthProvider>(context, listen: false).clearError();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isSignUp) {
      final successReq = await authProvider.requestOtp(
        _emailController.text.trim(),
      );
      if (successReq && mounted) {
        showOtpVerificationDialog(
          context,
          authProvider: authProvider,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );
      }
    } else {
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppMessage.loginSuccess.text),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LoginHeader(),
                  const SizedBox(height: 40),

                  Text(
                    _isSignUp ? "Tạo tài khoản" : "Chào mừng trở lại",
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                        ? "Nhập thông tin để đăng ký"
                        : "Đăng nhập để mua hoa và quản lý đơn hàng",
                    style: textTheme.bodyMedium,
                  ),
                  if (authProvider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    InlineAuthError(message: authProvider.errorMessage!),
                  ],
                  const SizedBox(height: 24),

                  // Fields
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Họ và tên",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      onChanged: (_) => _clearBackendError(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppMessage.nameRequired.text;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    onChanged: (_) => _clearBackendError(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppMessage.emailRequired.text;
                      }
                      if (!value.contains('@')) {
                        return AppMessage.emailInvalid.text;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Số điện thoại",
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      onChanged: (_) => _clearBackendError(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppMessage.phoneRequired.text;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: "Địa chỉ giao hàng",
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      onChanged: (_) => _clearBackendError(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppMessage.deliveryAddressRequired.text;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onChanged: (_) => _clearBackendError(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppMessage.passwordRequired.text;
                      }
                      if (value.length < 6) {
                        return AppMessage.passwordTooShort.text;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  authProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _submit,
                          child: Text(_isSignUp ? "Đăng ký" : "Đăng nhập"),
                        ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp ? "Đã có tài khoản? " : "Chưa có tài khoản? ",
                        style: textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            _formKey.currentState?.reset();
                          });
                          authProvider.clearError();
                        },
                        child: Text(
                          _isSignUp ? "Đăng nhập" : "Đăng ký ngay",
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
