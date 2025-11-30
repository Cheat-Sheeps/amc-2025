import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

import '../services/firebase_service.dart';
import '../models/chat_message.dart' as model;

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final double trustScore;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    required this.trustScore,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  void _showRating() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate ${widget.otherUserName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your trading experience?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () async {
                    final service = Provider.of<FirebaseService>(context, listen: false);
                    await service.updateTrustScore(widget.otherUserId, rating.toDouble());
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Rated ${widget.otherUserName} $rating stars')),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context, listen: false);
    final currentUser = ChatUser(
      id: service.user?.uid ?? 'unknown',
      firstName: 'You',
    );
    final otherUser = ChatUser(
      id: widget.otherUserId,
      firstName: widget.otherUserName,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${widget.trustScore.toStringAsFixed(1)} Trust',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review),
            tooltip: 'Rate User',
            onPressed: _showRating,
          ),
        ],
      ),
      body: StreamBuilder<List<model.ChatMessage>>(
        stream: service.streamMessages(widget.matchId),
        builder: (context, snapshot) {
          final messages = (snapshot.data ?? []).map((msg) {
            return ChatMessage(
              user: msg.senderId == currentUser.id ? currentUser : otherUser,
              text: msg.text,
              createdAt: msg.timestamp,
            );
          }).toList();

          return DashChat(
            currentUser: currentUser,
            onSend: (ChatMessage message) {
              service.sendMessage(widget.matchId, message.text);
            },
            messages: messages.reversed.toList(),
            messageOptions: MessageOptions(
              currentUserContainerColor: Colors.deepPurple,
              containerColor: Colors.grey[300]!,
              textColor: Colors.black,
            ),
            inputOptions: InputOptions(
              inputDecoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              sendButtonBuilder: (onSend) {
                return IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: onSend,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
