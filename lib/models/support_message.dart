class SupportMessage {
  SupportMessage({
    required this.id,
    required this.userRole,
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String userRole;
  final String sender;
  final String text;
  final DateTime createdAt;

  bool get fromSupport => sender == 'support';

  Map<String, dynamic> toJson() => {
    'id': id,
    'userRole': userRole,
    'sender': sender,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id']?.toString() ?? '',
      userRole: json['userRole']?.toString() ?? 'turista',
      sender: json['sender']?.toString() ?? 'user',
      text: json['text']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
