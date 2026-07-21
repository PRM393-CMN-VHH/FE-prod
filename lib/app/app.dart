import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/app/app_providers.dart';
import 'package:prm393/core/constants/app_strings.dart';
import 'package:prm393/core/routes/app_routes.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/notifications/widgets/notification_banner_host.dart';

// Module-level (not per-build) so the key stays stable across rebuilds of
// FlowerShopApp — NotificationBannerHost uses it to push routes from outside
// the routed widget tree.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

class FlowerShopApp extends StatelessWidget {
  const FlowerShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final navigatorKey = _rootNavigatorKey;
    return MultiProvider(
      providers: appProviders,
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        initialRoute: AppRoutes.auth,
        routes: AppRoutes.routes,
        // Chạm ra ngoài ô nhập liệu ở bất kỳ màn hình nào sẽ tắt bàn phím.
        builder: (context, child) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: NotificationBannerHost(
              navigatorKey: navigatorKey,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
