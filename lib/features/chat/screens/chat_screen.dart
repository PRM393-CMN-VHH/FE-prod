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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    // Allow UI to render and scroll
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    // Also scroll again after mock typing finished and reply is received
    Future.delayed(const Duration(milliseconds: 1200), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final chatProv = Provider.of<ChatProvider>(context);
    final messages = chatProv.messages;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Message Area
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
                    return ChatMessageBubble(message: messages[index]);
                  },
                ),
        ),

        // Typing simulator indicator
        if (chatProv.isTyping)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Support Agent is typing...",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        // Input Panel
        ChatInputBar(controller: _messageController, onSend: _sendMessage),
      ],
    );
  }
}
