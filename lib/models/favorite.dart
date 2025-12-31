import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a user's favorite item.
class FavoriteModel {
  final String id;
  final String userId;
  final String itemId;
  final String itemType; // 'job', 'service', 'rental'
  final String itemTitle;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
    required this.createdAt,
  });

  // --- Type Getters ---

  bool get isJob => itemType == 'job';
  bool get isService => itemType == 'service';
  bool get isRental => itemType == 'rental';

  // --- Serialization ---

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'itemId': itemId,
      'itemType': itemType,
      'itemTitle': itemTitle,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FavoriteModel.fromMap(Map<String, dynamic> map, String id) {
    return FavoriteModel(
      id: id,
      userId: map['userId'] ?? '',
      itemId: map['itemId'] ?? '',
      itemType: map['itemType'] ?? '',
      itemTitle: map['itemTitle'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'FavoriteModel(id: $id, itemType: $itemType, itemId: $itemId)';
  }
}
