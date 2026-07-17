class MessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final DateTime timestamp;
  final bool read;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.timestamp,
    this.read = false,
  });

  bool get isFromAdmin => senderRole.toLowerCase() == 'admin';

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['messageId'] is int
          ? json['messageId'] as int
          : int.tryParse(json['messageId'].toString()) ?? 0,
      conversationId: json['conversationId'] is int
          ? json['conversationId'] as int
          : int.tryParse(json['conversationId'].toString()) ?? 0,
      senderId: json['senderId'] is int
          ? json['senderId'] as int
          : int.tryParse(json['senderId'].toString()) ?? 0,
      senderName: json['senderName'] as String? ?? '',
      senderRole: json['senderRole'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timestamp: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : DateTime.now(),
      read: json['read'] as bool? ?? false,
    );
  }
}
