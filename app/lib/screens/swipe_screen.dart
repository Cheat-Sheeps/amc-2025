import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

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
  bool get _vibrationAvailableOnPlatform {
    // Only attempt to use the vibration plugin on Android or iOS (not on web or desktop)
    if (kIsWeb) return false;
    return (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  }

  // Centralized safe vibration helper. All vibration requests should go through this
  // to avoid calling platform channels on unsupported platforms (desktop/web)
  Future<void> _tryVibrate({int duration = 50, int amplitude = 128}) async {
    if (!_vibrationAvailableOnPlatform) return;
    try {
      final has = await Vibration.hasVibrator();
      if (has == true) {
        await Vibration.vibrate(duration: duration, amplitude: amplitude);
      }
    } catch (e) {
      // Ignore any errors from the vibration plugin (e.g. MissingPluginException)
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
        // increase toolbar height to avoid clipping of a large title
        toolbarHeight: 64,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
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
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: cardSwiper(items, service, context),
                  ),
                ),
              ),
            ],
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
              // Only try vibration on mobile platforms where the plugin is supported
              if (_vibrationAvailableOnPlatform) {
                // Sharp tap for reject
                await _tryVibrate(duration: 40, amplitude: 255);
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
              // Only try vibration on mobile platforms where the plugin is supported
              if (_vibrationAvailableOnPlatform) {
                // Satisfying buzz for like
                await _tryVibrate(duration: 80, amplitude: 150);
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
    const int thresholdPercent = 50; // percent of card width used by CardSwiper.threshold
    return CardSwiper(
      threshold: thresholdPercent,
      controller: controller,
      cardsCount: items.length,
      numberOfCardsDisplayed: math.min(items.length, 3),
      allowedSwipeDirection: AllowedSwipeDirection.only(left: true, right: true),
      onSwipe: (previousIndex, currentIndex, direction) async {
        // Trigger haptic feedback only on supported platforms
        if (_vibrationAvailableOnPlatform) {
          if (direction == CardSwiperDirection.right) {
            // Smooth vibration for like (longer, satisfying)
            await _tryVibrate(duration: 100, amplitude: 128);
          } else if (direction == CardSwiperDirection.left) {
            // Sharp double tap for dislike
            await _tryVibrate(duration: 50, amplitude: 200);
            await Future.delayed(const Duration(milliseconds: 100));
            await _tryVibrate(duration: 50, amplitude: 200);
          }
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

            // compute swipe progress from the provided percent threshold parameter
            // percentThresholdX is positive when swiping right (accept) and negative when swiping left (reject)
            // percentThresholdX is provided as an integer percent (e.g. 25 = 25%).
            // The package computes it as roughly proportional to the horizontal pixel offset
            // (see CardSwiper internals). To avoid immediate strong values for small drags,
            // compute a normalized progress relative to the screen width instead. This maps
            // small pixel movements to tiny progress values and large moves closer to 1.0.
            final double percent = percentThresholdX.toDouble();
            final double screenWidth = MediaQuery.of(context).size.width;
            // The package reports percentThresholdX = (100 * left / threshold), so to recover
            // the horizontal pixel offset (left) we do: left = percent * threshold / 100.
            final double leftPixels = (percent * thresholdPercent / 100.0);
            // normalized in 0..1 range based on pixel offset vs screen width
            final double rawAbs = (leftPixels.abs() / screenWidth).clamp(0.0, 1.0);
            // keep the sign for color/icon placement
            final bool isPositive = leftPixels >= 0;

            // Map rawAbs through a larger dead-zone first (linear), then apply an ease curve for smoothness.
            // This ensures the tint only begins when the user has swiped a substantial amount.
            const double fadeStart = 0.20; // require at least 50% raw movement before any tint
            const double fadeEnd = 0.80; // reach full mapped value very close to the edge

            double mappedLinear = 0.0;
            if (rawAbs <= fadeStart) {
              mappedLinear = 0.0;
            } else if (rawAbs >= fadeEnd) {
              mappedLinear = 1.0;
            } else {
              mappedLinear = (rawAbs - fadeStart) / (fadeEnd - fadeStart);
            }

            // apply an ease-out curve to the mapped linear value for a nicer feel
            final double mapped = Curves.easeOut.transform(mappedLinear);

            final Color swipeColor = isPositive ? Colors.green : Colors.red;
            // cap the final overlay opacity (tunable)
            const double maxOverlayOpacity = 0.78;
            final double overlayOpacity = (mapped * maxOverlayOpacity).clamp(0.0, 0.85);

            // We'll only show the floating icon when the mapped progress is above a medium threshold
            final double iconVisibilityThreshold = 0.12;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // the main card
                Card(
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
                                                   Icon(Icons.person, size: 14, color: _getTrustColor(trustScore)),
                                                   const SizedBox(width: 4),
                                                   Text(
                                                     ownerProfile?.displayName ?? 'User',
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
                                                   Icon(trustScore >= 8.0 ? Icons.verified_user : Icons.shield, size: 14, color: _getTrustColor(trustScore)),
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
                 ),

                // colored overlay that follows swipe progress
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        color: swipeColor.withOpacity(overlayOpacity),
                      ),
                    ),
                  ),
                ),

                // floating accept/reject icon that fades and scales with mapped progress
                if (mapped > iconVisibilityThreshold)
                  Positioned(
                    top: 32,
                    // show the accept checkmark on the right when swiping right
                    left: !isPositive ? 32 : null,
                    right: isPositive ? 32 : null,
                    child: Opacity(
                      opacity: (mapped * 1.05).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.9 + (mapped * 0.6),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPositive ? Icons.check : Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
