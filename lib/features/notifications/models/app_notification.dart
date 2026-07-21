class NotificationModel {
  final int id;
  final String title;
  final String content;
  final DateTime timestamp;
  bool isRead;
  final int? orderId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.orderId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['notificationId'] ?? json['id'] ?? 0;
    final rawTime = json['createdAt'] ?? json['timestamp'];
    final rawOrderId = json['orderId'];
    return NotificationModel(
      id: rawId is int ? rawId : int.parse(rawId.toString()),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timestamp: rawTime != null
          ? DateTime.parse(rawTime as String)
          : DateTime.now(),
      isRead:
          json['read'] == true || json['is_read'] == true || json['is_read'] == 1,
      orderId: rawOrderId is int
          ? rawOrderId
          : (rawOrderId == null ? null : int.tryParse(rawOrderId.toString())),
    );
  }
}
