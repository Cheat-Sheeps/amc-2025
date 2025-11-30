import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import '../models/item.dart';
import '../services/firebase_service.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController controller = CardSwiperController();

  Color _getTrustColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    return Colors.red;
  }

  void _preloadImages(List<Item> items, BuildContext context) {
    // Preload the next 3 images
    for (int i = 0; i < items.length && i < 3; i++) {
      if (items[i].imageUrl != null) {
        precacheImage(NetworkImage(items[i].imageUrl!), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '> BARTR  ',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            Text(
              'Montreal, QC',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Item>>(
        stream: service.streamItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          
          // Preload images when items are loaded
          if (items.isNotEmpty) {
            _preloadImages(items, context);
          }
          
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('No items yet!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'No items available for trading\nCreate your own or seed sample data from Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [Expanded(child: Center(child: cardSwiper(items, service, context)))],
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(List<Item> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.close,
            color: Colors.grey[800]!,
            iconColor: Colors.grey,
            size: 48,
            onPressed: () async {
              try {
                if (await Vibration.hasVibrator()) {
                  // Sharp tap for reject
                  Vibration.vibrate(duration: 40, amplitude: 255);
                }
              } catch (e) {
                // Vibration not supported
              }
              controller.swipe(CardSwiperDirection.left);
            },
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.whatshot,
            color: Theme.of(context).colorScheme.primary,
            iconColor: Theme.of(context).scaffoldBackgroundColor,
            size: 48,
            onPressed: () async {
              try {
                if (await Vibration.hasVibrator()) {
                  // Satisfying buzz for like
                  Vibration.vibrate(duration: 80, amplitude: 150);
                }
              } catch (e) {
                // Vibration not supported
              }
              controller.swipe(CardSwiperDirection.right);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required double size,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, spreadRadius: 2, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: size * 0.45),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  CardSwiper cardSwiper(List<Item> items, FirebaseService service, BuildContext context) {
    return CardSwiper(
      controller: controller,
      cardsCount: items.length,
      allowedSwipeDirection: AllowedSwipeDirection.only(left: true, right: true),
      onSwipe: (previousIndex, currentIndex, direction) async {
        // Trigger haptic feedback
        try {
            if (direction == CardSwiperDirection.right) {
              // Smooth vibration for like (longer, satisfying)
              Vibration.vibrate(duration: 100, amplitude: 128);
            } else if (direction == CardSwiperDirection.left) {
              // Sharp double tap for dislike
              Vibration.vibrate(duration: 50, amplitude: 200);
              await Future.delayed(const Duration(milliseconds: 100));
              Vibration.vibrate(duration: 50, amplitude: 200);
          }
        } catch (e) {
          // Vibration not supported, ignore
        }
        
        if (direction == CardSwiperDirection.right) {
          final item = items[previousIndex];
          service.likeItem(item.id ?? '');
        }
        
        // Preload next images after swiping
        if (currentIndex != null && currentIndex < items.length) {
          final nextIndex = currentIndex + 2; // Preload 2 ahead
          if (nextIndex < items.length && items[nextIndex].imageUrl != null) {
            precacheImage(NetworkImage(items[nextIndex].imageUrl!), context);
          }
        }
        
        return true;
      },
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        final item = items[index];
        // Use a keyed FutureBuilder to prevent rebuilding on swipe
        return FutureBuilder(
          key: ValueKey(item.id),
          future: Future.wait([service.getUserProfile(item.ownerId), service.getUserProfile(service.user?.uid ?? '')]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            final ownerProfile = snapshot.data?[0];
            final myProfile = snapshot.data?[1];
            final trustScore = ownerProfile?.trustScore ?? 5.0;
            final completedTrades = ownerProfile?.completedTrades ?? 0;

            final distance = service.calculateDistance(
              myProfile?.latitude,
              myProfile?.longitude,
              item.latitude,
              item.longitude,
            );

            return Card(
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: item.imageUrl != null
                              ? Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 64)),
                        ),
                        // Gradient overlay at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(.9)],
                              ),
                            ),
                          ),
                        ),
                        if (distance != null)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
                                boxShadow: [
                                  BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${distance.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Item info overlay at bottom
                        Positioned(
                          bottom: 20,
                          left: 16,
                          right: 16,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surface,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: _getTrustColor(trustScore), width: 1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getTrustColor(trustScore).withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.shield, size: 14, color: _getTrustColor(trustScore)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${trustScore.toStringAsFixed(1)}',
                                                style: TextStyle(
                                                  color: _getTrustColor(trustScore),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surface,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.handshake, size: 14, color: Theme.of(context).colorScheme.secondary),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$completedTrades',
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.secondary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              _buildActionButtons(items),
                            ],
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
    );
  }
}
