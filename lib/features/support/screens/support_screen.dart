import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prm393/features/chat/providers/chat_provider.dart';
import 'package:prm393/features/chat/screens/chat_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ChatProvider>(context, listen: false).markAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ChatScreen();
  }
}
