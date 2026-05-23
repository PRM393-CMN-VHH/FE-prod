import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/providers/chat_provider.dart';
import 'package:prm393/theme/app_theme.dart';

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
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg.sender == 'user';
                    final timeStr = "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isUser ? AppTheme.primaryColor : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isUser ? 16 : 0),
                                  bottomRight: Radius.circular(isUser ? 0 : 16),
                                ),
                                border: isUser
                                    ? null
                                    : Border.all(color: Colors.grey.shade200, width: 1),
                              ),
                              child: Text(
                                msg.content,
                                style: TextStyle(
                                  color: isUser ? Colors.white : AppTheme.textPrimaryColor,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Color(0xFFF9F7F7),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
