class ConversationSummary {
  final int conversationId;
  final int customerId;
  final String customerName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ConversationSummary({
    required this.conversationId,
    required this.customerId,
    required this.customerName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  ConversationSummary copyWith({String? lastMessage, DateTime? lastMessageAt, int? unreadCount}) {
    return ConversationSummary(
      conversationId: conversationId,
      customerId: customerId,
      customerName: customerName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      conversationId: json['conversationId'] is int
          ? json['conversationId'] as int
          : int.tryParse(json['conversationId'].toString()) ?? 0,
      customerId: json['customerId'] is int
          ? json['customerId'] as int
          : int.tryParse(json['customerId'].toString()) ?? 0,
      customerName: json['customerName'] as String? ?? '',
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      unreadCount: json['unreadCount'] is int
          ? json['unreadCount'] as int
          : int.tryParse(json['unreadCount'].toString()) ?? 0,
    );
  }
}
