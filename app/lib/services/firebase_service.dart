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

  User? get user => _auth.currentUser;

  Future<bool> ensureSignedIn() async {
    if (_auth.currentUser != null) return true;
    try {
      final cred = await _auth.signInAnonymously();
      final uid = cred.user?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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
    return _firestore.collection('items').snapshots().map((snap) {
      return snap.docs.map((d) => Item.fromDoc(d)).toList();
    });
  }

  Stream<List<Item>> streamUserItems() {
    if (user == null) return Stream.value([]);
    return _firestore
        .collection('items')
        .where('ownerId', isEqualTo: user!.uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Item.fromDoc(d)).toList());
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
    await _firestore.collection('items').add(item.toMap());
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

    // Check if the item owner has liked any of current user's items
    final myItems = await _firestore.collection('items').where('ownerId', isEqualTo: uid).get();
    final myItemIds = myItems.docs.map((d) => d.id).toList();
    
    if (myItemIds.isEmpty) return;

    final ownerLikes = await _firestore
        .collection('likes')
        .where('userId', isEqualTo: itemOwnerId)
        .where('itemId', whereIn: myItemIds)
        .get();

    // If owner liked one of my items, create a match
    if (ownerLikes.docs.isNotEmpty) {
      final matchId = uid.compareTo(itemOwnerId) < 0 ? '${uid}_$itemOwnerId' : '${itemOwnerId}_$uid';
      await _firestore.collection('matches').doc(matchId).set({
        'users': [uid, itemOwnerId],
        'itemId': itemId,
        'matchedItemId': ownerLikes.docs.first.data()['itemId'],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.id, doc.data() ?? {});
    } catch (e) {
      if (kDebugMode) print('Error getting user profile: $e');
      return null;
    }
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
    final message = ChatMessage(
      id: '',
      matchId: matchId,
      senderId: user!.uid,
      text: text.trim(),
      timestamp: DateTime.now(),
    );
    await _firestore.collection('messages').add(message.toMap());
  }

  Stream<List<ChatMessage>> streamMessages(String matchId) {
    return _firestore
        .collection('messages')
        .where('matchId', isEqualTo: matchId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromDoc(d)).toList());
  }

  double? calculateDistance(double? lat1, double? lon1, double? lat2, double? lon2) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return null;
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // in km
  }
}
