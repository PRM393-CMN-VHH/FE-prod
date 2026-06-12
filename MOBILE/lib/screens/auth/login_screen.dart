import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/providers/auth_provider.dart';
import 'package:prm393/theme/app_theme.dart';

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
      final successReq = await authProvider.requestOtp(_emailController.text.trim());
      if (successReq && mounted) {
        _showOtpDialog(authProvider);
      }
    } else {
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng nhập thành công!"),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }

  void _showOtpDialog(AuthProvider authProvider) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                final otp = otpController.text.trim();
                if (otp.length != 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vui lòng nhập đủ 6 số OTP")),
                  );
                  return;
                }
                
                // Close dialog
                Navigator.pop(context);
                
                final success = await authProvider.signUp(
                  email: _emailController.text.trim(),
                  password: _passwordController.text,
                  name: _nameController.text.trim(),
                  phone: _phoneController.text.trim(),
                  address: _addressController.text.trim(),
                  otp: otp,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Đăng ký thành công!"),
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
                  // App branding
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
                    _InlineAuthError(message: authProvider.errorMessage!),
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
                          return "Vui lòng nhập họ tên";
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
                        return "Vui lòng nhập email";
                      }
                      if (!value.contains('@')) {
                        return "Email không hợp lệ";
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
                          return "Vui lòng nhập số điện thoại";
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
                          return "Vui lòng nhập địa chỉ giao hàng";
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
                        return "Vui lòng nhập mật khẩu";
                      }
                      if (value.length < 6) {
                        return "Mật khẩu phải có ít nhất 6 ký tự";
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

class _InlineAuthError extends StatelessWidget {
  final String message;

  const _InlineAuthError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
