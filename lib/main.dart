import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/providers/auth_provider.dart';
import 'package:prm393/providers/product_provider.dart';
import 'package:prm393/providers/cart_provider.dart';
import 'package:prm393/providers/order_provider.dart';
import 'package:prm393/providers/notification_provider.dart';
import 'package:prm393/providers/chat_provider.dart';
import 'package:prm393/providers/toast_provider.dart';
import 'package:prm393/screens/auth/login_screen.dart';
import 'package:prm393/screens/main_navigation.dart';
import 'package:prm393/services/api_service.dart';
import 'package:prm393/theme/app_theme.dart';
import 'package:prm393/widgets/top_toast_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().initializeSupabase(url: '', anonKey: '');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ToastProvider()),
      ],
      child: MaterialApp(
        title: 'Tiệm Hoa Xnh',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            TopToastOverlay(child: child ?? const SizedBox.shrink()),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isCheckingSession) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      return const MainNavigation();
    }

    return const LoginScreen();
  }
}
