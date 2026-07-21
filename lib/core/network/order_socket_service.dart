import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OrderSocketEvent {
  // 'new_order' | 'order_updated' | 'order_status_changed' | 'notification'
  final String type;
  final Map<String, dynamic> payload;

  OrderSocketEvent(this.type, this.payload);
}

// Thin wrapper around a plain (non-STOMP) WebSocket connection to the backend
// order/notification endpoint, mirroring ChatSocketService. Auth reuses the
// same session cookie as the REST client, sent as a handshake header.
//
// The backend keeps a single live session per userId (a new handshake replaces
// the old one), so this must be a shared singleton: OrderProvider, the admin
// order list, and NotificationProvider all listen on the same connection
// instead of opening one each and silently evicting each other.
class OrderSocketService {
  OrderSocketService._internal();
  static final OrderSocketService instance = OrderSocketService._internal();

  WebSocketChannel? _channel;
  StreamController<OrderSocketEvent>? _controller;
  StreamSubscription? _subscription;
  Future<void>? _connecting;

  Stream<OrderSocketEvent>? get events => _controller?.stream;
  bool get isConnected => _channel != null;

  Future<void> connect({required String wsUrl, required String? cookie}) {
    if (isConnected) return Future.value();
    return _connecting ??= _doConnect(wsUrl: wsUrl, cookie: cookie)
        .whenComplete(() => _connecting = null);
  }

  Future<void> _doConnect({required String wsUrl, required String? cookie}) async {
    // Custom handshake headers (needed to carry the session cookie) aren't
    // reliably supported by browsers, so real-time push is mobile/desktop-only;
    // web falls back to REST polling.
    if (kIsWeb || cookie == null) return;

    await disconnect();
    _controller = StreamController<OrderSocketEvent>.broadcast();

    try {
      final channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {'Cookie': cookie},
      );
      _channel = channel;
      _subscription = channel.stream.listen(
        (data) => _handleIncoming(data),
        onDone: () => _channel = null,
        onError: (_) => _channel = null,
        cancelOnError: true,
      );
    } catch (_) {
      _channel = null;
    }
  }

  void _handleIncoming(dynamic data) {
    try {
      final decoded = jsonDecode(data as String) as Map<String, dynamic>;
      final type = decoded['type'] as String? ?? '';
      final payload = decoded['payload'];
      if (type.isEmpty || payload is! Map) return;
      _controller?.add(OrderSocketEvent(type, Map<String, dynamic>.from(payload)));
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    await _controller?.close();
    _controller = null;
  }
}
