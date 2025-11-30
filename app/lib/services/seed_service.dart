import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _seedUsers() async {
    final users = [
      {
        'displayName': 'Alex Survivor',
        'trustScore': 9.2,
        'completedTrades': 47,
        'totalRatings': 50,
        'latitude': 45.5017,
        'longitude': -73.5673,
      },
      {
        'displayName': 'Jordan Trader',
        'trustScore': 7.8,
        'completedTrades': 23,
        'totalRatings': 28,
        'latitude': 45.5088,
        'longitude': -73.5878,
      },
      {
        'displayName': 'Sam Prepper',
        'trustScore': 8.5,
        'completedTrades': 35,
        'totalRatings': 40,
        'latitude': 45.4980,
        'longitude': -73.5780,
      },
    ];

    for (int i = 0; i < users.length; i++) {
      await _firestore.collection('users').doc('seed_user_${i + 1}').set(
        users[i],
        SetOptions(merge: true),
      );
    }
  }

  Future<void> seedDatabase(String userId) async {
    try {
      // Delete old items (in case they have broken Unsplash URLs)
      final existingItems = await _firestore.collection('items').get();
      for (final doc in existingItems.docs) {
        await doc.reference.delete();
      }
      if (kDebugMode) print('Cleared old seed data');

      // Create seed users with trust scores
      await _seedUsers();

      // Sample items for apocalypse bartering scenario with random locations
      final items = [
        {
          'title': 'Water Purification Tablets',
          'description': 'Essential for clean drinking water. 100 tablets, expires 2099.',
          'imageUrl': 'https://picsum.photos/800/600?random=1',
          'ownerId': 'seed_user_1',
          'latitude': 45.5017 + (0.1 - 0.05),
          'longitude': -73.5673 + (0.1 - 0.05),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Canned Food Stash',
          'description': '50 cans of various foods. Long shelf life.',
          'imageUrl': 'https://picsum.photos/800/600?random=2',
          'ownerId': 'seed_user_2',
          'latitude': 45.5088 + (0.05 - 0.025),
          'longitude': -73.5878 + (0.05 - 0.025),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'First Aid Kit',
          'description': 'Complete medical supplies including antibiotics and bandages.',
          'imageUrl': 'https://picsum.photos/800/600?random=3',
          'ownerId': 'seed_user_1',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Solar Generator',
          'description': 'Portable solar power generator. 1000W capacity.',
          'imageUrl': 'https://picsum.photos/800/600?random=4',
          'ownerId': 'seed_user_3',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Gas Mask & Filters',
          'description': 'Military grade gas mask with 10 replacement filters.',
          'imageUrl': 'https://picsum.photos/800/600?random=5',
          'ownerId': 'seed_user_2',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Survival Seeds Kit',
          'description': 'Non-GMO heirloom seeds for growing food. 20 varieties.',
          'imageUrl': 'https://picsum.photos/800/600?random=6',
          'ownerId': 'seed_user_3',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Portable Radio',
          'description': 'Hand-crank emergency radio with flashlight. No batteries needed.',
          'imageUrl': 'https://picsum.photos/800/600?random=7',
          'ownerId': 'seed_user_1',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Thermal Blankets',
          'description': 'Pack of 20 emergency thermal blankets.',
          'imageUrl': 'https://picsum.photos/800/600?random=8',
          'ownerId': 'seed_user_2',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Multi-tool Knife',
          'description': 'Swiss army style multi-tool with 15 functions.',
          'imageUrl': 'https://picsum.photos/800/600?random=9',
          'ownerId': 'seed_user_3',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Rope & Paracord Bundle',
          'description': '500ft of various rope and paracord for shelter building.',
          'imageUrl': 'https://picsum.photos/800/600?random=10',
          'ownerId': 'seed_user_1',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Hunting Crossbow',
          'description': 'Compound crossbow with 12 bolts. Perfect for hunting.',
          'imageUrl': 'https://picsum.photos/800/600?random=11',
          'ownerId': 'seed_user_2',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Camping Tent',
          'description': '6-person waterproof tent. Easy setup.',
          'imageUrl': 'https://picsum.photos/800/600?random=12',
          'ownerId': 'seed_user_3',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Antibiotics Stockpile',
          'description': 'Various antibiotics. Properly stored. Expires 2098.',
          'imageUrl': 'https://picsum.photos/800/600?random=13',
          'ownerId': 'seed_user_1',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Gasoline (50L)',
          'description': '50 liters of stabilized gasoline in jerry cans.',
          'imageUrl': 'https://picsum.photos/800/600?random=14',
          'ownerId': 'seed_user_2',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Walkie Talkies Set',
          'description': 'Long range walkie talkies. 50km range. Set of 4.',
          'imageUrl': 'https://picsum.photos/800/600?random=15',
          'ownerId': 'seed_user_3',
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add items in batch
      final batch = _firestore.batch();
      for (final item in items) {
        final docRef = _firestore.collection('items').doc();
        batch.set(docRef, item);
      }
      await batch.commit();

      if (kDebugMode) print('Database seeded successfully with ${items.length} items');
    } catch (e) {
      if (kDebugMode) print('Error seeding database: $e');
      rethrow;
    }
  }
}
