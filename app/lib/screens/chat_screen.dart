import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_service.dart';
import '../models/chat_message.dart' as model;
import '../models/user_profile.dart';

import 'other_user_profile_screen.dart';

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
  void _acceptDeal(FirebaseService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Deal'),
        content: const Text('Are you sure you want to accept this deal? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await service.acceptDeal(widget.matchId);
              Navigator.pop(context);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

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
                  icon: const Icon(
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

  Widget _buildDealStatusFooter(FirebaseService service) {
    return StreamBuilder<DocumentSnapshot>(
      stream: service.streamMatch(widget.matchId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final matchData = snapshot.data!.data() as Map<String, dynamic>?;
        if (matchData == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deal completed! Offer and item for sale delisted.'),
                ),
              );
              Navigator.pop(context);
            }
          });
          return const SizedBox.shrink();
        }

        final acceptedBy = (matchData['acceptedBy'] as List<dynamic>?)?.cast<String>() ?? [];
        final currentUserAccepted = acceptedBy.contains(service.user!.uid);
        final otherUserAccepted = acceptedBy.contains(widget.otherUserId);

        return FutureBuilder<List<UserProfile?>>(
          future: Future.wait<UserProfile?>([
            service.getUserProfile(service.user!.uid),
            service.getUserProfile(widget.otherUserId),
          ]),
          builder: (context, profileSnapshot) {
            if (!profileSnapshot.hasData) {
              return const SizedBox.shrink();
            }
            final myProfile = profileSnapshot.data?[0];
            final otherProfile = profileSnapshot.data?[1];

            final distance = service.calculateDistance(
              myProfile?.latitude,
              myProfile?.longitude,
              otherProfile?.latitude,
              otherProfile?.longitude,
            );

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withAlpha(77),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatusIndicator(
                      title: 'You',
                      subtitle: currentUserAccepted ? '(accepted)' : '(click to accept)',
                      isAccepted: currentUserAccepted,
                      onTap: currentUserAccepted ? null : () => _acceptDeal(service),
                    ),
                  ),
                  _buildDistanceIndicator(distance),
                  Expanded(
                    child: _buildStatusIndicator(
                      title: widget.otherUserName,
                      subtitle: otherUserAccepted ? '(accepted)' : '(not accepted)',
                      isAccepted: otherUserAccepted,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusIndicator({
    required String title,
    required String subtitle,
    required bool isAccepted,
    VoidCallback? onTap,
  }) {
    final bool isInteractive = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAccepted ? Icons.check_circle : Icons.check_circle_outline,
            color: isAccepted
                ? Colors.green
                : (isInteractive ? Theme.of(context).colorScheme.secondary : Colors.grey),
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isInteractive ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isInteractive
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceIndicator(double? distance) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.swap_horiz,
          color: Theme.of(context).colorScheme.secondary,
          size: 32,
        ),
        const SizedBox(height: 4),
        if (distance != null)
          Text(
            '${distance.toStringAsFixed(1)} km',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
      ],
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
                color: Theme.of(context).colorScheme.primary.withAlpha(77),
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
                    Icons.handshake,
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
              color: Theme.of(context).colorScheme.primary.withAlpha(77),
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
            color: Theme.of(context).colorScheme.primary.withAlpha(178),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context, listen: false);
    final currentUser = ChatUser(id: service.user!.uid);
    final otherUser = ChatUser(id: widget.otherUserId, firstName: widget.otherUserName);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherUserProfileScreen(
                userId: widget.otherUserId,
                userName: widget.otherUserName,
                trustScore: widget.trustScore,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.person),
              const SizedBox(width: 8),
              Text(widget.otherUserName),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _showRating,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
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
                        color: Theme.of(context).colorScheme.primary.withAlpha(128),
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
                          color: Theme.of(context).colorScheme.primary.withAlpha(77),
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
          _buildDealStatusFooter(service),
        ],
      ),
    );
  }
}
