import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:prm393/features/auth/providers/auth_provider.dart';
import 'package:prm393/features/cart/providers/cart_provider.dart';
import 'package:prm393/features/catalog/providers/product_provider.dart';
import 'package:prm393/features/chat/providers/chat_provider.dart';
import 'package:prm393/features/admin/providers/admin_chat_provider.dart';
import 'package:prm393/features/notifications/providers/notification_provider.dart';
import 'package:prm393/features/orders/providers/order_provider.dart';

final List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => ProductProvider()),
  ChangeNotifierProvider(create: (_) => CartProvider()),
  ChangeNotifierProvider(create: (_) => OrderProvider()),
  ChangeNotifierProvider(create: (_) => NotificationProvider()),
  ChangeNotifierProvider(create: (_) => ChatProvider()),
  ChangeNotifierProvider(create: (_) => AdminChatProvider()),
];
