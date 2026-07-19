import 'package:prm393/features/chat/models/message.dart';
import 'package:prm393/features/chat/models/conversation_summary.dart';
import 'package:prm393/core/network/api_client_base.dart';

/// Messaging / chat: real-time via WebSocket, REST for history.
mixin ChatApi on ApiClientBase {
  // The chat WebSocket path isn't an http(s) REST call, so it's resolved
  // separately (ws(s):// scheme) rather than through request().
  static String get wsChatUrl => ApiClientBase.backendBaseUrl
      .replaceFirst(RegExp(r'^http'), 'ws') + ApiEndpoints.wsChat.path;

  // Customer: fetch (or implicitly create) their own conversation + full history.
  Future<Map<String, dynamic>> getMyConversation() async {
    final result = await request(ApiEndpoints.chatConversation);
    return result as Map<String, dynamic>;
  }

  // Admin: list of all customer conversations with last message + unread count.
  Future<List<ConversationSummary>> getConversations() async {
    final result = await request(ApiEndpoints.chatConversations);
    return (result as List<dynamic>)
        .map((json) => ConversationSummary.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<MessageModel>> getConversationMessages(int conversationId) async {
    final result = await request(
      ApiEndpoints.chatConversationMessages,
      params: {'conversationId': conversationId},
    );
    return (result as List<dynamic>)
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Customer sends a message in their own conversation.
  Future<MessageModel> sendMyMessage(String content) async {
    final result = await request(
      ApiEndpoints.chatSendMyMessage,
      body: {'content': content},
    );
    return MessageModel.fromJson(result as Map<String, dynamic>);
  }

  // Admin replies in a specific conversation.
  Future<MessageModel> sendMessageToConversation(
    int conversationId,
    String content,
  ) async {
    final result = await request(
      ApiEndpoints.chatSendConversationMessage,
      params: {'conversationId': conversationId},
      body: {'content': content},
    );
    return MessageModel.fromJson(result as Map<String, dynamic>);
  }

  Future<void> markConversationRead(int conversationId) async {
    await request(
      ApiEndpoints.chatMarkRead,
      params: {'conversationId': conversationId},
    );
  }

  Future<int> getUnreadChatCount() async {
    final result = await request(ApiEndpoints.chatUnreadCount);
    final count = (result as Map<String, dynamic>)['unreadCount'];
    return count is int ? count : int.tryParse(count.toString()) ?? 0;
  }
}
