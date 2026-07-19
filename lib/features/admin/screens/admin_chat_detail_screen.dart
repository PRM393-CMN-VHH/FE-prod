import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/features/admin/providers/admin_chat_provider.dart';
import 'package:prm393/features/chat/widgets/chat_input_bar.dart';
import 'package:prm393/features/chat/widgets/chat_message_bubble.dart';
import 'package:prm393/core/theme/app_theme.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final int conversationId;
  final String customerName;

  const AdminChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.customerName,
  });

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  AdminChatProvider? _adminChatProvider;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProv = Provider.of<AdminChatProvider>(context, listen: false);
      await chatProv.openConversation(widget.conversationId);
      await chatProv.markAsRead(widget.conversationId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chatProv = Provider.of<AdminChatProvider>(context, listen: false);
    if (_adminChatProvider != chatProv) {
      _adminChatProvider?.removeListener(_onChatChanged);
      _adminChatProvider = chatProv;
      _adminChatProvider?.addListener(_onChatChanged);
      _lastMessageCount = _adminChatProvider?.messagesFor(widget.conversationId).length ?? 0;
    }
  }

  @override
  void dispose() {
    _adminChatProvider?.removeListener(_onChatChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChatChanged() {
    if (!mounted) return;
    final messages = _adminChatProvider?.messagesFor(widget.conversationId) ?? [];
    if (messages.length > _lastMessageCount) {
      final isNewMessageFromMe = messages.isNotEmpty && messages.last.isFromAdmin;

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

    final chatProv = Provider.of<AdminChatProvider>(context, listen: false);
    _messageController.clear();
    await chatProv.sendMessage(widget.conversationId, text);
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<AdminChatProvider>().messagesFor(
      widget.conversationId,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(widget.customerName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ChatMessageBubble(
                  message: message,
                  isMine: message.isFromAdmin,
                );
              },
            ),
          ),
          ChatInputBar(controller: _messageController, onSend: _sendMessage),
        ],
      ),
    );
  }
}
