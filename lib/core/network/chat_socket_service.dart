import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatSocketEvent {
  final String type; // 'message' or 'unread_count'
  final dynamic payload;

  ChatSocketEvent(this.type, this.payload);
}

// Thin wrapper around a plain (non-STOMP) WebSocket connection to the backend
// chat endpoint. Auth reuses the same session cookie as the REST client, sent
// as a handshake header.
class ChatSocketService {
  WebSocketChannel? _channel;
  StreamController<ChatSocketEvent>? _controller;
  StreamSubscription? _subscription;

  Stream<ChatSocketEvent>? get events => _controller?.stream;
  bool get isConnected => _channel != null;

  Future<void> connect({required String wsUrl, required String? cookie}) async {
    // Custom handshake headers (needed to carry the session cookie) aren't
    // reliably supported by browsers, so real-time push is mobile/desktop-only;
    // web falls back to REST polling.
    if (kIsWeb || cookie == null) return;

    await disconnect();
    _controller = StreamController<ChatSocketEvent>.broadcast();

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
      if (type == 'message') {
        _controller?.add(ChatSocketEvent('message', decoded['payload']));
      } else if (type == 'unread_count') {
        _controller?.add(ChatSocketEvent('unread_count', decoded['count']));
      }
    } catch (_) {}
  }

  void send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
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
