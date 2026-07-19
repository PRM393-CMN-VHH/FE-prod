import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/core/constants/app_messages.dart';
import 'package:prm393/features/auth/providers/auth_provider.dart';
import 'package:prm393/features/profile/widgets/profile_error_banner.dart';
import 'package:prm393/core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
    _addressController.text = user?.address ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ok = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? AppMessage.profileUpdated.text
              : authProvider.errorMessage ??
                    AppMessage.profileUpdateFailed.text,
        ),
        backgroundColor: ok ? AppTheme.primaryColor : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: authProvider.refreshProfile,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              (user?.name.isNotEmpty ?? false)
                  ? user!.name.substring(0, 1).toUpperCase()
                  : "?",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.email ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),
          if (authProvider.errorMessage != null) ...[
            ProfileErrorBanner(message: authProvider.errorMessage!),
            const SizedBox(height: 16),
          ],
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Họ và tên",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppMessage.nameRequired.text;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Số điện thoại",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
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
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Địa chỉ giao hàng",
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppMessage.addressRequired.text;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                authProvider.isLoading
                    ? const CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text("Lưu thay đổi"),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              // Confirm logout
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(AppMessage.logoutTitle.text),
                  content: Text(AppMessage.logoutConfirmMessage.text),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(AppMessage.cancelAction.text),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        authProvider.signOut();
                      },
                      child: Text(
                        AppMessage.logoutTitle.text,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.logout_outlined),
            label: Text(AppMessage.logoutTitle.text),
          ),
        ],
      ),
    );
  }
}
