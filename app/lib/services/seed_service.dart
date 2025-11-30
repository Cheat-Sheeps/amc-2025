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
      // Delete old items EXCEPT those owned by current user
      final existingItems = await _firestore.collection('items').get();
      for (final doc in existingItems.docs) {
        final data = doc.data();
        if (data['ownerId'] != userId) {
          await doc.reference.delete();
        }
      }
      if (kDebugMode) print('Cleared old seed data (preserved current user items)');
      
      // Clear old matches and likes
      final existingMatches = await _firestore.collection('matches').get();
      for (final doc in existingMatches.docs) {
        await doc.reference.delete();
      }
      final existingLikes = await _firestore.collection('likes').get();
      for (final doc in existingLikes.docs) {
        await doc.reference.delete();
      }

      // Create seed users with trust scores
      await _seedUsers();

      // Sample items for apocalypse bartering scenario with random locations
      final items = [
        {
          'title': 'Mysterious Pills',
          'description': 'This is your last chance. After this, there is no turning back.',
          'imageUrl': 'https://media.discordapp.net/attachments/1411465635803828266/1444709437674618880/Generated_Image_November_29_2025_-_7_40PM.png?ex=692db203&is=692c6083&hm=a58dbf97de69c15dce1c40dd04b4ffc4296ccda52c0bb784e4366b452af7b043&=&format=webp&quality=lossless&width=803&height=803',
          'ownerId': 'seed_user_1',
          'latitude': 45.5017 + (0.01),
          'longitude': -73.5673 + (0.01),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Water Purification Tablets',
          'description': 'quickly remove bacteria from water, most unused, come in packs of 3',
          'imageUrl': 'https://i.ytimg.com/vi/T0o7Uy70NjE/maxresdefault.jpg',
          'ownerId': 'seed_user_2',
          'latitude': 45.5088 + (0.02),
          'longitude': -73.5878 + (0.02),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Portable Solar Charger',
          'description': 'Refurbished solar charger i found in abandoned building, i dont need it cuz i use gas generator',
          'imageUrl': 'https://content.instructables.com/ORIG/FID/MDOY/HKVLCQAG/FIDMDOYHKVLCQAG.jpg?auto=webp&frame=1&width=2100',
          'ownerId': 'seed_user_3',
          'latitude': 45.4980 - (0.01),
          'longitude': -73.5780 - (0.01),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'multi-tool knife',
          'description': 'high quality swiss knife w accessories, a bit dull but u can sharpen it easy',
          'imageUrl': 'https://7gadgets.com/wp-content/uploads/2020/02/Victorinox-Swiss-Army-Multi-Tool.jpg',
          'ownerId': 'seed_user_1',
          'latitude': 45.5017 + (0.003),
          'longitude': -73.5673 + (0.003),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'First aid kit',
          'description': 'comes with bandages, sterile pads, alcohol, peroxide, ointments and gels, standard stuff',
          'imageUrl': 'https://media.cnn.com/api/v1/images/stellar/prod/band-aid-johnson-johnson-3.jpg?q=h_900,w_1600,x_0,y_0',
          'ownerId': 'seed_user_2',
          'latitude': 45.5088 - (0.002),
          'longitude': -73.5878 + (0.004),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Geiger Counter',
          'description': 'if it ticks too quickly, your probably dead soon',
          'imageUrl': 'https://www.howitworksdaily.com/wp-content/uploads/2017/08/geiger-muller.jpg',
          'ownerId': 'seed_user_3',
          'latitude': 45.4980 + (0.005),
          'longitude': -73.5780 - (0.003),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Cambelts tomatoes and onions canned soup',
          'description': 'best before: 2067',
          'imageUrl': 'https://s.yimg.com/ny/api/res/1.2/_l29gdSZJSc1iLedQX7kOw--/YXBwaWQ9aGlnaGxhbmRlcjt3PTk2MDtoPTY0MDtjZj13ZWJw/https://media.zenfs.com/en/cbc.ca/d7a5350116297e556700b6e98b74419d',
          'ownerId': 'seed_user_1',
          'latitude': 45.5017 - (0.004),
          'longitude': -73.5673 + (0.002),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Heavy duty gloves',
          'description': 'made of nylon, very strong, they lasted me 2 years and still countin',
          'imageUrl': 'https://firmgrip.com/cdn/shop/files/65242_Lifestyle_1_1220x_crop_center.jpg?v=1725372909',
          'ownerId': 'seed_user_2',
          'latitude': 45.5088 + (0.006),
          'longitude': -73.5878 - (0.001),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Crowbar',
          'description': 'the tool of choice for a freeman',
          'imageUrl': 'https://facts.net/wp-content/uploads/2024/01/7-best-crowbar-1706505919.jpg',
          'ownerId': 'seed_user_3',
          'latitude': 45.4980 - (0.002),
          'longitude': -73.5780 + (0.004),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'portable stove',
          'description': 'le rond en bas a gauche est pèté mais le reste y marche',
          'imageUrl': 'https://loots.pk/cdn/shop/files/C6B35D0E-BD5A-431A-B1C5-5285BF343F49.jpg?v=1704778138',
          'ownerId': 'seed_user_1',
          'latitude': 45.5017 + (0.007),
          'longitude': -73.5673 - (0.003),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'seed packets',
          'description': 'seeds for og kush, sour diesel and tomatoes i think. not checked so buy at ur own risk',
          'imageUrl': 'https://royalkingseeds.com/feesoasa/2023/11/Bag-Seeds.jpg',
          'ownerId': 'seed_user_2',
          'latitude': 45.5088 - (0.003),
          'longitude': -73.5878 + (0.005),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Rope',
          'description': 'not sure id trust it for climbing but should be sturdy enough for most tasks',
          'imageUrl': 'https://tse4.mm.bing.net/th/id/OIP.-XORoJ-wQ0tm4YoOmgV0YgHaFx?rs=1&pid=ImgDetMain&o=7&rm=3',
          'ownerId': 'seed_user_3',
          'latitude': 45.4980 + (0.004),
          'longitude': -73.5780 - (0.002),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'warm wool blanket',
          'description': 'very soft and warm, thick',
          'imageUrl': 'https://lifeundercanvas.co.uk/wp-content/uploads/2016/05/blue-blankets.jpg',
          'ownerId': 'seed_user_1',
          'latitude': 45.5017 - (0.005),
          'longitude': -73.5673 + (0.006),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'iron shovel',
          'description': 'its not diamond but it digs well',
          'imageUrl': 'https://ae01.alicdn.com/kf/Se0623c4f75e04755be8768db9607a5cc6/Outdoor-Wide-Snow-Shovel-Portable-Snow-Shovel-with-Metal-Blade-Suitable-and-Large-Capacity-for-Snow.jpg',
          'ownerId': 'seed_user_2',
          'latitude': 45.5088 + (0.003),
          'longitude': -73.5878 - (0.004),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'hiking boots',
          'description': 'very soft and warm, thick',
          'imageUrl': 'https://th.bing.com/th/id/OIP.lSRME6yQIvcVahdiiyat7gHaEo?o=7rm=3&rs=1&pid=ImgDetMain&o=7&rm=3',
          'ownerId': 'seed_user_3',
          'latitude': 45.4980 - (0.006),
          'longitude': -73.5780 + (0.003),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'lost Sumsang S67 1tb, unlocked + SIM',
          'description': 'excellent condition, brand new, OLED 8K HDR10+ 250hz, gaming phone, pro phone, iPhone',
          'imageUrl': 'https://images.squarespace-cdn.com/content/v1/66104511dc163c65c82c9ea1/1713192918438-C01AB0J757NC2ANS8JYP/Cracked-Screen-Phone-3-1200x1200-cropped.jpeg?format=1000w',
          'ownerId': 'seed_user_1',
          'latitude': 45.5017 + (0.008),
          'longitude': -73.5673 - (0.005),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Heavy-duty Flashlight',
          'description': 'brighter than you',
          'imageUrl': 'https://tse1.mm.bing.net/th/id/OIP.LINYOw-O5xrhvYUsxkhOcgHaHa?rs=1&pid=ImgDetMain&o=7&rm=3',
          'ownerId': 'seed_user_2',
          'latitude': 45.5088 - (0.004),
          'longitude': -73.5878 + (0.003),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Gasoline generator',
          'description': 'climate change isnt much of an issue anymore since 90% of us are dead so dont feel too bad',
          'imageUrl': 'https://image.made-in-china.com/2f0j00dsaTEqDLhnoV/Portable-4-Stroke-Gasoline-Generator-1kw-Honda-Style.jpg',
          'ownerId': 'seed_user_3',
          'latitude': 45.4980 + (0.002),
          'longitude': -73.5780 - (0.006),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Super Power Bank',
          'description': 'High-capacity solar charger for essential electronics.',
          'imageUrl': 'https://img.kwcdn.com/product/fancy/01626c45-78c7-4f09-abc3-23468e931b33.jpg?imageView2/2/w/500/q/70/format/webp',
          'ownerId': 'seed_user_1',
          'latitude': 45.5017 - (0.003),
          'longitude': -73.5673 + (0.007),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Tactical Backpack',
          'description': 'very durable, buy it please i need to feed me family.',
          'imageUrl': 'https://tse3.mm.bing.net/th/id/OIP.k0nqK9zevRUBbU9ZlyUWJQHaE8?rs=1&pid=ImgDetMain&o=7&rm=3',
          'ownerId': 'seed_user_2',
          'latitude': 45.5088 + (0.004),
          'longitude': -73.5878 - (0.002),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'broken emergency radio',
          'description': 'idk what to do to fix it but maybe youll have better luck or for salvaging',
          'imageUrl': 'https://tse2.mm.bing.net/th/id/OIP.cZcAK6Qv8YGjQhJSOtFQfwHaFj?rs=1&pid=ImgDetMain&o=7&rm=3',
          'ownerId': 'seed_user_3',
          'latitude': 45.4980 - (0.004),
          'longitude': -73.5780 + (0.005),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'handmade crossbow + bolts',
          'description': 'high quality hand carved oak and forged iron crossbow, comes with bolts + resupply offer',
          'imageUrl': 'https://2img.net/h/i1175.photobucket.com/albums/r625/weskuhn/_DSC0089_1024x685_zps9ea1c185.jpg',
          'ownerId': 'seed_user_1',
          'latitude': 45.5017 + (0.005),
          'longitude': -73.5673 - (0.004),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Gas Mask',
          'description': 'VERY GOOD mask offering EXCELLENT protection from smoke AND airborne hazards BUY NOWWW.',
          'imageUrl': 'https://th.bing.com/th/id/OIP.r4yNR2aPdk7W1mi3UZhtZgHaFj?o=7rm=3&rs=1&pid=ImgDetMain&o=7&rm=3',
          'ownerId': 'seed_user_2',
          'latitude': 45.5088 - (0.005),
          'longitude': -73.5878 + (0.006),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Fire-starter Kit',
          'description': 'Magnesium fire-starter for reliable ignition in any weather.',
          'imageUrl': 'https://sursto.b-cdn.net/wp-content/uploads/2023/06/Survival-Fire-Starting-Kit.png',
          'ownerId': 'seed_user_3',
          'latitude': 45.4980 + (0.006),
          'longitude': -73.5780 - (0.004),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Insulated Sleeping Bag',
          'description': 'it has a few holes but its still warm, just patch it up',
          'imageUrl': 'https://th.bing.com/th/id/R.58e2abc97a7bf4b26e351e3a5dfe4cfc?rik=8CmkKRnBJoGjUQ&pid=ImgRaw&r=0',
          'ownerId': 'seed_user_1',
          'latitude': 45.5017 - (0.006),
          'longitude': -73.5673 + (0.004),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Mocrisoft 367 Family subscription',
          'description': 'come with mocrisoft write, mocrisoft xxxl and mocrisoft mot de pouvoir',
          'imageUrl': 'https://th.bing.com/th/id/R.40a5d5942a5bb7fff402b4bea0012508?rik=mvRQjVphjSEU5w&pid=ImgRaw&r=0',
          'ownerId': 'seed_user_2',
          'latitude': 45.5088 + (0.002),
          'longitude': -73.5878 - (0.005),
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add items in batch
      final batch = _firestore.batch();
      final itemIds = <String>[];
      for (final item in items) {
        final docRef = _firestore.collection('items').doc();
        batch.set(docRef, item);
        itemIds.add(docRef.id);
      }
      await batch.commit();

      // Get current user's items
      final myItemsQuery = await _firestore
          .collection('items')
          .where('ownerId', isEqualTo: userId)
          .get();
      final myItemIds = myItemsQuery.docs.map((doc) => doc.id).toList();

      // Create some pre-existing likes to simulate matches
      // Have seed_user_1 like items from seed_user_2 and seed_user_3
      // Have seed_user_2 like items from seed_user_1
      // Have all seed users like the current user's items for instant matches
      
      final likeBatch = _firestore.batch();
      
      // seed_user_1 likes items owned by seed_user_2 (indices 1, 4, 7, 10, 13)
      for (int i = 1; i < itemIds.length; i += 3) {
        final likeRef = _firestore.collection('likes').doc();
        likeBatch.set(likeRef, {
          'itemId': itemIds[i],
          'userId': 'seed_user_1',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      // seed_user_2 likes items owned by seed_user_1 (indices 0, 2, 6, 9, 12)
      for (int i = 0; i < itemIds.length; i += 3) {
        final likeRef = _firestore.collection('likes').doc();
        likeBatch.set(likeRef, {
          'itemId': itemIds[i],
          'userId': 'seed_user_2',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      // seed_user_3 likes some items too (indices 0, 1, 2)
      for (int i = 0; i < 3 && i < itemIds.length; i++) {
        final likeRef = _firestore.collection('likes').doc();
        likeBatch.set(likeRef, {
          'itemId': itemIds[i],
          'userId': 'seed_user_3',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Have all seed users like the current user's items (for instant matches)
      for (final myItemId in myItemIds) {
        for (final seedUser in ['seed_user_1', 'seed_user_2', 'seed_user_3']) {
          final likeRef = _firestore.collection('likes').doc();
          likeBatch.set(likeRef, {
            'itemId': myItemId,
            'userId': seedUser,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await likeBatch.commit();
      
      if (kDebugMode) print('Seed users now like ${myItemIds.length} of your items');

      if (kDebugMode) print('Database seeded successfully with ${items.length} items and pre-seeded likes for matches');
    } catch (e) {
      if (kDebugMode) print('Error seeding database: $e');
      rethrow;
    }
  }
}
