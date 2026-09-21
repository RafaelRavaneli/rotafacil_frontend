class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderRole,
    required this.recipientRole,
    required this.text,
    required this.createdAt,
    this.guideName = '',
  });

  final String id;
  final String senderRole;
  final String recipientRole;
  final String text;
  final DateTime createdAt;
  final String guideName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderRole': senderRole,
        'recipientRole': recipientRole,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'guideName': guideName,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final oldRole = json['role']?.toString();
    final oldSentByMe = json['sentByMe'] == true;

    String sender = json['senderRole']?.toString() ?? '';
    String recipient = json['recipientRole']?.toString() ?? '';

    if (sender.isEmpty && oldRole != null) {
      if (oldRole == 'guia') {
        sender = oldSentByMe ? 'guia' : 'turista';
        recipient = oldSentByMe ? 'turista' : 'guia';
      } else {
        sender = oldSentByMe ? 'turista' : 'guia';
        recipient = oldSentByMe ? 'guia' : 'turista';
      }
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderRole: sender.isEmpty ? 'turista' : sender,
      recipientRole: recipient.isEmpty ? 'guia' : recipient,
      text: json['text']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      guideName: json['guideName']?.toString() ?? '',
    );
  }
}
