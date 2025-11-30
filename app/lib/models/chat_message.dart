import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String matchId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      matchId: data['matchId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}
