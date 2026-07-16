import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/auth/providers/auth_provider.dart';
import 'package:prm393/features/auth/screens/login_screen.dart';
import 'package:prm393/features/navigation/screens/main_navigation_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isCheckingSession) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return authProvider.isAuthenticated
        ? const MainNavigation()
        : const LoginScreen();
  }
}
