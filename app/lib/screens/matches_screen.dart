import 'package:amc/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Matches'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.streamMatches(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No matches yet',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Swipe right on items to start matching!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                itemCount: matches.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
              final match = matches[index];
              final matchId = match['id'] as String;
              final users = (match['users'] as List<dynamic>?) ?? [];
              final otherUserId = users.firstWhere(
                (id) => id != service.user?.uid,
                orElse: () => 'unknown',
              );

              final itemId = match['itemId'] as String?;
              final matchedItemId = match['matchedItemId'] as String?;
              
              return FutureBuilder<List<dynamic>>(
                future: Future.wait<dynamic>([
                  service.getUserProfile(otherUserId),
                  itemId != null ? service.getItem(itemId) : Future.value(null),
                ]),
                builder: (context, AsyncSnapshot<List<dynamic>> profileSnap) {
                  final profile = profileSnap.data?[0] as UserProfile?;
                  final itemData = profileSnap.data?[1] as Map<String, dynamic>?;
                  final displayName = profile?.displayName ?? 'User $otherUserId';
                  final trustScore = profile?.trustScore ?? 5.0;
                  final itemTitle = itemData?['title'] as String? ?? 'Unknown Item';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          displayName[0].toUpperCase(),
                          style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor),
                        ),
                      ),
                      title: Text(displayName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.inventory_2, size: 14, color: Theme.of(context).colorScheme.secondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  itemTitle,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text('${trustScore.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11)),
                                const SizedBox(width: 12),
                                Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                                const SizedBox(width: 2),
                                Text('${profile?.completedTrades ?? 0}', style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chat_bubble_outline),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              matchId: matchId,
                              otherUserId: otherUserId,
                              otherUserName: displayName,
                              trustScore: trustScore,
                              itemId: itemId,
                              matchedItemId: matchedItemId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
