class MessageModel {
  final int id;
  final String content;
  final String sender; // 'user' or 'store'
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      content: json['content'] as String,
      sender: json['sender'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
