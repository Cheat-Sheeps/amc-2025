import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String? id;
  final String title;
  final String description;
  final String? imageUrl;
  final String ownerId;
  final double? latitude;
  final double? longitude;

  Item({
    this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.ownerId,
    this.latitude,
    this.longitude,
  });

  factory Item.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Item(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      ownerId: data['ownerId'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
