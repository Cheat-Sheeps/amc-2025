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
  final String? itemId;
  final String? matchedItemId;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    required this.trustScore,
    this.itemId,
    this.matchedItemId,
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

  Widget _buildMatchedItemsHeader(FirebaseService service) {
    if (widget.itemId == null || widget.matchedItemId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        service.getItem(widget.itemId!),
        service.getItem(widget.matchedItemId!),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final myItem = snapshot.data?[0] as Map<String, dynamic>?;
        final theirItem = snapshot.data?[1] as Map<String, dynamic>?;
        
        if (myItem == null || theirItem == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                '> MATCHED ITEMS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Their item
                  Expanded(
                    child: _buildItemPreview(
                      theirItem['title'] ?? 'Unknown',
                      theirItem['imageUrl'] ?? '',
                      widget.otherUserName,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Arrow
                  Icon(
                    Icons.swap_horiz,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  // My item
                  Expanded(
                    child: _buildItemPreview(
                      myItem['title'] ?? 'Unknown',
                      myItem['imageUrl'] ?? '',
                      'You',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemPreview(String title, String imageUrl, String owner) {
    return Column(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Icon(
                        Icons.inventory_2,
                        color: Theme.of(context).colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  )
                : Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Icon(
                      Icons.inventory_2,
                      color: Theme.of(context).colorScheme.primary,
                      size: 40,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          owner,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
        ),
      ],
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '> ${widget.otherUserName.toUpperCase()}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            Row(
              children: [
                Icon(Icons.star, size: 12, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  '${widget.trustScore.toStringAsFixed(1)} TRUST',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.rate_review, color: Theme.of(context).colorScheme.primary),
            tooltip: 'Rate User',
            onPressed: _showRating,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Hide matched items header when keyboard is visible
            if (MediaQuery.of(context).viewInsets.bottom == 0)
              _buildMatchedItemsHeader(service),
            Expanded(
              child: StreamBuilder<List<model.ChatMessage>>(
                stream: service.streamMessages(widget.matchId),
                builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading messages: ${snapshot.error}',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  );
                }
                
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
                    currentUserContainerColor: Theme.of(context).colorScheme.primary,
                    containerColor: Theme.of(context).colorScheme.surface,
                    textColor: Theme.of(context).colorScheme.primary,
                    currentUserTextColor: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: 12,
                    messagePadding: const EdgeInsets.all(12),
                  ),
                  inputOptions: InputOptions(
                    inputDecoration: InputDecoration(
                      hintText: '> TYPE MESSAGE...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        letterSpacing: 1,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    inputTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    sendOnEnter: true,
                    sendButtonBuilder: (onSend) {
                      return IconButton(
                        icon: Icon(Icons.send, color: Theme.of(context).colorScheme.secondary),
                        onPressed: onSend,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ));
  }
}
