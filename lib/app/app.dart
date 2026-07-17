import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/app/app_providers.dart';
import 'package:prm393/core/constants/app_strings.dart';
import 'package:prm393/core/routes/app_routes.dart';
import 'package:prm393/core/theme/app_theme.dart';

class FlowerShopApp extends StatelessWidget {
  const FlowerShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appProviders,
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.auth,
        routes: AppRoutes.routes,
        // Chạm ra ngoài ô nhập liệu ở bất kỳ màn hình nào sẽ tắt bàn phím.
        builder: (context, child) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child,
          );
        },
      ),
    );
  }
}
