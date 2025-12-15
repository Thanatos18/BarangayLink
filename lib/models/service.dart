import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final double rate; // ₱ per hour or per task
  final String providerId; // UID of the provider
  final String providerName; // Denormalized for easy display
  final String barangay;
  final List<String> imageUrls;
  final String contactNumber;
  final String status; // "Available", "Unavailable"
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rate,
    required this.providerId,
    required this.providerName,
    required this.barangay,
    this.imageUrls = const [],
    required this.contactNumber,
    this.status = 'Available',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAvailable => status == 'Available';

  factory ServiceModel.fromMap(Map<String, dynamic> data, String id) {
    return ServiceModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      rate: (data['rate'] as num?)?.toDouble() ?? 0.0,
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? 'Unknown',
      barangay: data['barangay'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      contactNumber: data['contactNumber'] ?? '',
      status: data['status'] ?? 'Available',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'rate': rate,
      'providerId': providerId,
      'providerName': providerName,
      'barangay': barangay,
      'imageUrls': imageUrls,
      'contactNumber': contactNumber,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ServiceModel copyWith({
    String? name,
    String? description,
    String? category,
    double? rate,
    String? barangay,
    List<String>? imageUrls,
    String? contactNumber,
    String? status,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id,
      providerId: providerId,
      providerName: providerName,
      createdAt: createdAt,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      rate: rate ?? this.rate,
      barangay: barangay ?? this.barangay,
      imageUrls: imageUrls ?? this.imageUrls,
      contactNumber: contactNumber ?? this.contactNumber,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
