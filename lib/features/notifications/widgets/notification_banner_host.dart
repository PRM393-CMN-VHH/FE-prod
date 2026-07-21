import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/core/theme/app_theme.dart';
import 'package:prm393/features/auth/providers/auth_provider.dart';
import 'package:prm393/features/notifications/models/app_notification.dart';
import 'package:prm393/features/notifications/providers/notification_provider.dart';
import 'package:prm393/features/orders/screens/order_detail_screen.dart';

// Sits above the whole app (wrapped around MaterialApp's routed content) and
// slides a top banner in whenever NotificationProvider pushes a live socket
// event, regardless of which screen is currently open. Tapping it navigates
// straight to the order it's about; it also auto-dismisses after a few seconds.
class NotificationBannerHost extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const NotificationBannerHost({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<NotificationBannerHost> createState() => _NotificationBannerHostState();
}

class _NotificationBannerHostState extends State<NotificationBannerHost> {
  StreamSubscription<NotificationModel>? _subscription;
  NotificationModel? _visible;
  NotificationModel? _lastRendered;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      _subscription = provider.bannerStream.listen(_show);
    });
  }

  void _show(NotificationModel notif) {
    _dismissTimer?.cancel();
    setState(() {
      _visible = notif;
      _lastRendered = notif;
    });
    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    if (mounted) setState(() => _visible = null);
  }

  void _handleTap() {
    final notif = _visible;
    _dismiss();
    final orderId = notif?.orderId;
    if (orderId == null) return;

    final navState = widget.navigatorKey.currentState;
    final navContext = widget.navigatorKey.currentContext;
    if (navState == null || navContext == null) return;
    final isAdmin =
        Provider.of<AuthProvider>(navContext, listen: false).user?.isAdmin ??
        false;
    navState.push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: orderId, isAdmin: isAdmin),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notif = _lastRendered;
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: AnimatedSlide(
              offset: _visible != null ? Offset.zero : const Offset(0, -1.3),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _visible != null ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: notif == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: GestureDetector(
                            onTap: _handleTap,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.notifications_active,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notif.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          notif.content,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _dismiss,
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 8, top: 2),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
