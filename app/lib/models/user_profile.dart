class UserProfile {
  final String id;
  final String? displayName;
  final double trustScore;
  final int completedTrades;
  final int totalRatings;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSeen;

  UserProfile({
    required this.id,
    this.displayName,
    this.trustScore = 5.0,
    this.completedTrades = 0,
    this.totalRatings = 0,
    this.latitude,
    this.longitude,
    this.lastSeen,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      displayName: data['displayName'],
      trustScore: (data['trustScore'] ?? 5.0).toDouble(),
      completedTrades: data['completedTrades'] ?? 0,
      totalRatings: data['totalRatings'] ?? 0,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      lastSeen: data['lastSeen']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'trustScore': trustScore,
      'completedTrades': completedTrades,
      'totalRatings': totalRatings,
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': lastSeen,
    };
  }
}
