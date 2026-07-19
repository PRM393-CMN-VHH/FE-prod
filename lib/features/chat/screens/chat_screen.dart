import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/features/chat/providers/chat_provider.dart';
import 'package:prm393/features/chat/widgets/chat_input_bar.dart';
import 'package:prm393/features/chat/widgets/chat_message_bubble.dart';
import 'package:prm393/core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  ChatProvider? _chatProvider;
  int _lastMessageCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chatProv = Provider.of<ChatProvider>(context, listen: false);
    if (_chatProvider != chatProv) {
      _chatProvider?.removeListener(_onChatChanged);
      _chatProvider = chatProv;
      _chatProvider?.addListener(_onChatChanged);
      _lastMessageCount = _chatProvider?.messages.length ?? 0;
    }
  }

  @override
  void dispose() {
    _chatProvider?.removeListener(_onChatChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChatChanged() {
    if (!mounted) return;
    final messages = _chatProvider?.messages ?? [];
    if (messages.length > _lastMessageCount) {
      final isNewMessageFromMe = messages.isNotEmpty && !messages.last.isFromAdmin;

      bool isAtBottom = true;
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        isAtBottom = (position.maxScrollExtent - position.pixels) <= 100;
      }

      _lastMessageCount = messages.length;

      if (isNewMessageFromMe || isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } else {
      _lastMessageCount = messages.length;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProv = Provider.of<ChatProvider>(context, listen: false);
    _messageController.clear();

    await chatProv.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final chatProv = Provider.of<ChatProvider>(context);
    final messages = chatProv.messages;

    return Column(
      children: [
        Expanded(
          child: chatProv.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatMessageBubble(
                      message: message,
                      isMine: !message.isFromAdmin,
                    );
                  },
                ),
        ),
        ChatInputBar(controller: _messageController, onSend: _sendMessage),
      ],
    );
  }
}
