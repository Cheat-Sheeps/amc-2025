import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/item.dart';
import '../models/user_profile.dart';
import '../models/chat_message.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Cache for user profiles
  final Map<String, UserProfile> _profileCache = {};
  final Map<String, DateTime> _profileCacheTime = {};
  static const _cacheExpiration = Duration(minutes: 5);

  User? get user => _auth.currentUser;

  Future<bool> ensureSignedIn() async {
    if (_auth.currentUser != null) return true;
    try {
      final cred = await _auth.signInAnonymously();
      final uid = cred.user?.uid;
      if (uid != null) {
        // Create user profile
        await _firestore.collection('users').doc(uid).set({
          'createdAt': FieldValue.serverTimestamp(),
          'displayName': 'Survivor',
          'trustScore': 5.0,
          'completedTrades': 0,
          'totalRatings': 0,
          'latitude': 45.5017,
          'longitude': -73.5673,
        }, SetOptions(merge: true));
        
        // Create a starter item for the new user
        await _firestore.collection('items').add({
          'title': 'Water Bottle',
          'description': 'Essential for survival. Half full.',
          'imageUrl': 'https://picsum.photos/800/600?random=999',
          'ownerId': uid,
          'latitude': 45.5017,
          'longitude': -73.5673,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        if (kDebugMode) print('Created new user with starter item');
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Auth error: $e');
        print('Please enable Anonymous Authentication in Firebase Console:');
        print('https://console.firebase.google.com/project/amc-2025/authentication/providers');
      }
      rethrow;
    }
    return false;
  }

  Stream<List<Item>> streamItems() {
    if (user == null) return Stream.value([]);
    final uid = user!.uid;
    return _firestore.collection('items').snapshots().map((snap) {
      // Filter out current user's own items
      final items = snap.docs
          .where((d) => d.data()['ownerId'] != uid)
          .map((d) => Item.fromDoc(d))
          .toList();
      // Randomize the order
      items.shuffle();
      return items;
    });
  }

  Future<Map<String, dynamic>?> getItem(String itemId) async {
    try {
      final doc = await _firestore.collection('items').doc(itemId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data() ?? {}};
    } catch (e) {
      if (kDebugMode) print('Error getting item: $e');
      return null;
    }
  }

  Stream<List<Item>> streamUserItems() {
    if (user == null) return Stream.value([]);
    return _firestore
        .collection('items')
        .where('ownerId', isEqualTo: user!.uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Item.fromDoc(d)).toList());
  }

  // Fetch items for a specific user (for the profile view)
  Future<List<Item>> getItemsForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('ownerId', isEqualTo: userId)
          .get();
      
      return snapshot.docs.map((d) => Item.fromDoc(d)).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching user items: $e');
      return [];
    }
  }

  Future<String?> uploadImage(dynamic fileOrBytes, String path) async {
    final ref = _storage.ref().child(path);
    UploadTask upload;
    if (kIsWeb) {
      // On web, use putData with Uint8List
      final bytes = fileOrBytes is Uint8List ? fileOrBytes : Uint8List.fromList(fileOrBytes as List<int>);
      upload = ref.putData(bytes);
    } else {
      // On mobile/desktop, use putFile
      upload = ref.putFile(fileOrBytes as File);
    }
    final snapshot = await upload;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> createItem(Item item) async {
    final docRef = await _firestore.collection('items').add(item.toMap());
    final newItemId = docRef.id;
    
    // Have seed users automatically like new items for instant matches
    final batch = _firestore.batch();
    for (final seedUser in ['seed_user_1', 'seed_user_2', 'seed_user_3']) {
      final likeRef = _firestore.collection('likes').doc();
      batch.set(likeRef, {
        'itemId': newItemId,
        'userId': seedUser,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    
    if (kDebugMode) print('Created item with auto-likes from seed users');
  }

  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }

  Future<void> likeItem(String itemId) async {
    if (user == null) return;
    final uid = user!.uid;
    
    // Record the like
    final doc = _firestore.collection('likes').doc();
    await doc.set({
      'itemId': itemId,
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Check for mutual match
    // Get the item owner
    final itemDoc = await _firestore.collection('items').doc(itemId).get();
    if (!itemDoc.exists) return;
    final itemOwnerId = itemDoc.data()?['ownerId'];
    if (itemOwnerId == null || itemOwnerId == uid) return;

    // Check if the item owner has liked any of the current user's items
    final myItems = await _firestore.collection('items').where('ownerId', isEqualTo: uid).get();
    final myItemIds = myItems.docs.map((d) => d.id).toList();
    
    if (myItemIds.isEmpty) {
      if (kDebugMode) print('No items owned by current user, cannot create match');
      return;
    }
    
    if (kDebugMode) print('Checking if $itemOwnerId liked any of my ${myItemIds.length} items: $myItemIds');

    final ownerLikes = await _firestore
        .collection('likes')
        .where('userId', isEqualTo: itemOwnerId)
        .where('itemId', whereIn: myItemIds)
        .get();
    
    if (kDebugMode) print('Found ${ownerLikes.docs.length} likes from $itemOwnerId on my items');

    // If owner liked one of my items, create a match
    if (ownerLikes.docs.isNotEmpty) {
      final matchId = uid.compareTo(itemOwnerId) < 0 ? '${uid}_$itemOwnerId' : '${itemOwnerId}_$uid';
      final likedItemId = ownerLikes.docs.first.data()['itemId'] as String;
      
      await _firestore.collection('matches').doc(matchId).set({
        'users': [uid, itemOwnerId],
        'itemId': itemId, // The item I liked
        'matchedItemId': likedItemId, // The item they liked of mine
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (kDebugMode) print('Match created! They liked $likedItemId, I liked $itemId');
    }
  }

  Stream<List<Map<String, dynamic>>> streamMatches() {
    if (user == null) return Stream.value([]);
    final uid = user!.uid;
    return _firestore
        .collection('matches')
        .where('users', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> acceptDeal(String matchId) async {
    if (user == null) return;
    final uid = user!.uid;
    final matchRef = _firestore.collection('matches').doc(matchId);

    await _firestore.runTransaction((transaction) async {
      final matchDoc = await transaction.get(matchRef);
      if (!matchDoc.exists) return;

      final data = matchDoc.data() ?? {};
      final acceptedBy = (data['acceptedBy'] as List<dynamic>?)?.cast<String>() ?? [];

      if (!acceptedBy.contains(uid)) {
        acceptedBy.add(uid);
        transaction.update(matchRef, {'acceptedBy': acceptedBy});
      }

      if (acceptedBy.length >= 2) {
        final itemId = data['itemId'] as String?;
        final matchedItemId = data['matchedItemId'] as String?;

        if (itemId != null) {
          transaction.delete(_firestore.collection('items').doc(itemId));
        }
        if (matchedItemId != null) {
          transaction.delete(_firestore.collection('items').doc(matchedItemId));
        }
        transaction.delete(matchRef);
      }
    });
  }

  Future<void> updateUserLocation(Position position) async {
    if (user == null) return;
    await _firestore.collection('users').doc(user!.uid).update({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      // Check if we have a valid cached profile
      final cachedTime = _profileCacheTime[userId];
      if (cachedTime != null && 
          DateTime.now().difference(cachedTime) < _cacheExpiration &&
          _profileCache.containsKey(userId)) {
        return _profileCache[userId];
      }
      
      // Fetch from Firestore
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      
      final profile = UserProfile.fromMap(doc.id, doc.data() ?? {});
      
      // Cache the profile
      _profileCache[userId] = profile;
      _profileCacheTime[userId] = DateTime.now();
      
      return profile;
    } catch (e) {
      if (kDebugMode) print('Error getting user profile: $e');
      return null;
    }
  }
  
  void clearProfileCache() {
    _profileCache.clear();
    _profileCacheTime.clear();
  }

  Future<void> updateUserProfile(String userId, {String? displayName}) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update(updates);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
    if (kDebugMode) print('User signed out');
  }

  Future<void> updateTrustScore(String userId, double rating) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data() ?? {};
    final currentScore = (data['trustScore'] ?? 5.0).toDouble();
    final totalRatings = (data['totalRatings'] ?? 0) as int;
    final newTotalRatings = totalRatings + 1;
    final newScore = ((currentScore * totalRatings) + rating) / newTotalRatings;

    await _firestore.collection('users').doc(userId).update({
      'trustScore': newScore,
      'totalRatings': newTotalRatings,
    });
  }

  Future<void> sendMessage(String matchId, String text) async {
    if (user == null || text.trim().isEmpty) return;
    try {
      final message = ChatMessage(
        id: '',
        matchId: matchId,
        senderId: user!.uid,
        text: text.trim(),
        timestamp: DateTime.now(),
      );
      await _firestore.collection('messages').add(message.toMap());
      if (kDebugMode) print('Message sent successfully');
    } catch (e) {
      if (kDebugMode) print('Error sending message: $e');
      rethrow;
    }
  }

  Stream<List<ChatMessage>> streamMessages(String matchId) {
    return _firestore
        .collection('messages')
        .where('matchId', isEqualTo: matchId)
        .snapshots()
        .map((snap) {
          final messages = snap.docs.map((d) => ChatMessage.fromDoc(d)).toList();
          // Sort in memory instead of requiring a Firestore index
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  double? calculateDistance(double? lat1, double? lon1, double? lat2, double? lon2) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return null;
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // in km
  }
}
