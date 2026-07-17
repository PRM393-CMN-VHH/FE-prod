import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/core/constants/app_messages.dart';
import 'package:prm393/features/admin/providers/admin_chat_provider.dart';
import 'package:prm393/features/admin/screens/admin_chat_detail_screen.dart';
import 'package:prm393/features/admin/widgets/admin_common_widgets.dart';
import 'package:prm393/core/theme/app_theme.dart';

class AdminChatTab extends StatelessWidget {
  const AdminChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<AdminChatProvider>();

    if (chatProv.isLoading && chatProv.conversations.isEmpty) {
      return const AdminLoading();
    }
    if (chatProv.errorMessage != null && chatProv.conversations.isEmpty) {
      return AdminErrorState(error: chatProv.errorMessage!);
    }
    if (chatProv.conversations.isEmpty) {
      return AdminEmptyState(
        text: AppMessage.adminEmptyConversations.text,
        icon: Icons.chat_bubble_outline,
      );
    }

    return RefreshIndicator(
      onRefresh: chatProv.loadConversations,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: chatProv.conversations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final conversation = chatProv.conversations[index];
          return AdminCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminChatDetailScreen(
                    conversationId: conversation.conversationId,
                    customerName: conversation.customerName,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    conversation.customerName.isNotEmpty
                        ? conversation.customerName[0].toUpperCase()
                        : "?",
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conversation.lastMessage ?? "Chưa có tin nhắn",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (conversation.unreadCount > 0)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
