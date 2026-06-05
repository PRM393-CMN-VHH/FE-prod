import 'package:flutter/material.dart';
import 'package:prm393/models/message.dart';
import 'package:prm393/services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false; // Simulates representative typing delay

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;

  Future<void> loadMessages() async {
    _isLoading = true;
    notifyListeners();

    try {
      _messages = await _apiService.getMessages();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    try {
      final userMsg = await _apiService.sendMessage(content, "user");
      _messages.add(userMsg);
      notifyListeners();

      // Trigger mock store reply simulation
      _isTyping = true;
      notifyListeners();

      final storeMsg = await _apiService.getMockAutoReply(content);
      if (storeMsg != null) {
        _messages.add(storeMsg);
      }
    } catch (_) {}

    _isTyping = false;
    notifyListeners();
  }
}
