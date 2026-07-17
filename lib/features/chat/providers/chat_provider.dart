import 'dart:async';
import 'package:flutter/material.dart';
import 'package:prm393/features/chat/models/message.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/network/chat_socket_service.dart';
import 'package:prm393/core/utils/error_translator.dart';

// Customer-side chat: a single conversation with the store, kept in sync live
// over a WebSocket (falls back to REST send/poll if the socket is unavailable).
class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ChatSocketService _socket = ChatSocketService();
  StreamSubscription<ChatSocketEvent>? _socketSubscription;

  int? _conversationId;
  List<MessageModel> _messages = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  int? get conversationId => _conversationId;
  List<MessageModel> get messages => _messages;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMessages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.getMyConversation();
      _conversationId = data['conversationId'] as int;
      _messages = (data['messages'] as List<dynamic>)
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
      _errorMessage = null;
      await _connectSocket();
      await refreshUnreadCount();
    } catch (e) {
      _errorMessage = ErrorTranslator.userMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _connectSocket() async {
    final cookie = await _apiService.getSessionCookie();
    await _socket.connect(wsUrl: ApiService.wsChatUrl, cookie: cookie);
    await _socketSubscription?.cancel();
    _socketSubscription = _socket.events?.listen(_handleSocketEvent);
  }

  void _handleSocketEvent(ChatSocketEvent event) {
    if (event.type == 'message') {
      final message = MessageModel.fromJson(event.payload as Map<String, dynamic>);
      if (message.conversationId != _conversationId) return;
      _messages.add(message);
      notifyListeners();
    } else if (event.type == 'unread_count') {
      final payload = event.payload;
      _unreadCount = payload is int ? payload : int.tryParse(payload.toString()) ?? 0;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    if (_socket.isConnected) {
      // The socket echoes the saved message back, so no optimistic add here.
      _socket.send({'content': content});
      return;
    }

    try {
      final message = await _apiService.sendMyMessage(content);
      _messages.add(message);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead() async {
    if (_conversationId == null || _unreadCount == 0) return;
    try {
      await _apiService.markConversationRead(_conversationId!);
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _apiService.getUnreadChatCount();
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _socket.disconnect();
    super.dispose();
  }
}
