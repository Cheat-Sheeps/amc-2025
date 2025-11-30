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

          return ListView.builder(
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

              return FutureBuilder(
                future: service.getUserProfile(otherUserId),
                builder: (context, profileSnap) {
                  final profile = profileSnap.data;
                  final displayName = profile?.displayName ?? 'User $otherUserId';
                  final trustScore = profile?.trustScore ?? 5.0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(displayName),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${trustScore.toStringAsFixed(1)} Trust Score'),
                          const SizedBox(width: 16),
                          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text('${profile?.completedTrades ?? 0} trades'),
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
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
