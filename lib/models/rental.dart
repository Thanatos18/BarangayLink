import 'package:cloud_firestore/cloud_firestore.dart';

class RentalModel {
  final String id;
  final String itemName;
  final String description;
  final String category;
  final double rentPrice; // ₱ per day
  final String ownerId; // UID of the owner
  final String ownerName; // Denormalized for easy display
  final String barangay;
  final List<String> imageUrls;
  final String condition; // "Good", "Fair", "Needs Repair"
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  RentalModel({
    required this.id,
    required this.itemName,
    required this.description,
    required this.category,
    required this.rentPrice,
    required this.ownerId,
    required this.ownerName,
    required this.barangay,
    this.imageUrls = const [],
    this.condition = 'Good',
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get status => isAvailable ? 'Available' : 'Rented';

  factory RentalModel.fromMap(Map<String, dynamic> data, String id) {
    return RentalModel(
      id: id,
      itemName: data['itemName'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      rentPrice: (data['rentPrice'] as num?)?.toDouble() ?? 0.0,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Unknown',
      barangay: data['barangay'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      condition: data['condition'] ?? 'Good',
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'description': description,
      'category': category,
      'rentPrice': rentPrice,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'barangay': barangay,
      'imageUrls': imageUrls,
      'condition': condition,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RentalModel copyWith({
    String? itemName,
    String? description,
    String? category,
    double? rentPrice,
    String? barangay,
    List<String>? imageUrls,
    String? condition,
    bool? isAvailable,
    DateTime? updatedAt,
  }) {
    return RentalModel(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      createdAt: createdAt,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      category: category ?? this.category,
      rentPrice: rentPrice ?? this.rentPrice,
      barangay: barangay ?? this.barangay,
      imageUrls: imageUrls ?? this.imageUrls,
      condition: condition ?? this.condition,
      isAvailable: isAvailable ?? this.isAvailable,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
