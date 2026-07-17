import 'dart:async';
import 'package:flutter/material.dart';
import 'package:prm393/features/chat/models/message.dart';
import 'package:prm393/features/chat/models/conversation_summary.dart';
import 'package:prm393/core/network/api_service.dart';
import 'package:prm393/core/network/chat_socket_service.dart';
import 'package:prm393/core/utils/error_translator.dart';

// Admin-side chat: the conversation list (one per customer) plus whichever
// threads have been opened, kept in sync live over a shared WebSocket.
class AdminChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ChatSocketService _socket = ChatSocketService();
  StreamSubscription<ChatSocketEvent>? _socketSubscription;

  List<ConversationSummary> _conversations = [];
  final Map<int, List<MessageModel>> _conversationMessages = {};
  int _totalUnreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<ConversationSummary> get conversations => _conversations;
  int get totalUnreadCount => _totalUnreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<MessageModel> messagesFor(int conversationId) =>
      _conversationMessages[conversationId] ?? [];

  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _conversations = await _apiService.getConversations();
      _totalUnreadCount = _conversations.fold(0, (sum, c) => sum + c.unreadCount);
      _errorMessage = null;
      await _connectSocket();
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
      final list = _conversationMessages.putIfAbsent(message.conversationId, () => []);
      list.add(message);

      final idx = _conversations.indexWhere((c) => c.conversationId == message.conversationId);
      if (idx != -1) {
        _conversations[idx] = _conversations[idx].copyWith(
          lastMessage: message.content,
          lastMessageAt: message.timestamp,
        );
      }
      notifyListeners();
    } else if (event.type == 'unread_count') {
      final payload = event.payload;
      _totalUnreadCount = payload is int ? payload : int.tryParse(payload.toString()) ?? 0;
      notifyListeners();
    }
  }

  Future<void> openConversation(int conversationId) async {
    try {
      final messages = await _apiService.getConversationMessages(conversationId);
      _conversationMessages[conversationId] = messages;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> sendMessage(int conversationId, String content) async {
    if (content.trim().isEmpty) return;

    if (_socket.isConnected) {
      // The socket echoes the saved message back, so no optimistic add here.
      _socket.send({'content': content, 'conversationId': conversationId});
      return;
    }

    try {
      final message = await _apiService.sendMessageToConversation(conversationId, content);
      final list = _conversationMessages.putIfAbsent(conversationId, () => []);
      list.add(message);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(int conversationId) async {
    try {
      await _apiService.markConversationRead(conversationId);
      final idx = _conversations.indexWhere((c) => c.conversationId == conversationId);
      if (idx != -1) {
        final previousUnread = _conversations[idx].unreadCount;
        _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
        _totalUnreadCount = (_totalUnreadCount - previousUnread).clamp(0, 1 << 31);
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _socket.disconnect();
    super.dispose();
  }
}
