import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/item.dart';
import '../models/user_profile.dart';

class OtherUserProfileScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final double trustScore;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.trustScore,
  });

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              const Color(0xFF1A251A), // Lighter green-black at top
              const Color(0xFF050705), // Deep black at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'SURVIVOR DOSSIER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          letterSpacing: 3,
                          fontSize: 14,
                          color: colorScheme.primary.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // The "ID Card" Look
                      FutureBuilder<UserProfile?>(
                        future: service.getUserProfile(userId),
                        builder: (context, snapshot) {
                          final profile = snapshot.data;
                          final trades = profile?.completedTrades ?? 0;
                          final ratings = profile?.totalRatings ?? 0;

                          return Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111611),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colorScheme.surface,
                                        border: Border.all(color: colorScheme.primary, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // Name and ID
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          Text(
                                            'ID: ${userId.substring(0, 8).toUpperCase()}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                              color: colorScheme.primary.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Stats Row
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStat(context, trustScore.toStringAsFixed(1), 'TRUST', Icons.star),
                                      _buildStat(context, '$trades', 'TRADES', Icons.handshake),
                                      _buildStat(context, '$ratings', 'RATINGS', Icons.rate_review),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Section Header with Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 16, color: colorScheme.secondary),
                            const SizedBox(width: 8),
                            Text(
                              'INVENTORY LOG',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.secondary,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: colorScheme.secondary.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Items Grid
                      FutureBuilder<List<Item>>(
                        future: service.getItemsForUser(userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            );
                          }
                          
                          final items = snapshot.data ?? [];

                          if (items.isEmpty) {
                            return Container(
                              margin: const EdgeInsets.all(32),
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                // FIXED: Removed BorderStyle.dashed
                                border: Border.all(color: Colors.grey[800]!, width: 2),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black26,
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.no_backpack_outlined, size: 48, color: Colors.grey[700]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'STASH EMPTY',
                                    style: TextStyle(color: Colors.grey[600], letterSpacing: 2),
                                  ),
                                ],
                              ),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141A14),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.15),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                        child: item.imageUrl != null
                                            ? Image.network(
                                                item.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_,__,___) => Container(
                                                  color: Colors.black26,
                                                  child: Icon(Icons.broken_image, color: Colors.grey[700]),
                                                ),
                                              )
                                            : Container(
                                                color: Colors.black26,
                                                child: Icon(Icons.inventory_2, size: 40, color: colorScheme.primary),
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: colorScheme.primary.withOpacity(0.6),
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label, IconData icon) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Icon(icon, size: 20, color: color.withOpacity(0.8)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.5),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}