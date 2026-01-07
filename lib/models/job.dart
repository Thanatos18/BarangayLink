import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final double wage;
  final String postedBy; // UID of the poster
  final String posterName; // Denormalized for easy display
  final String barangay;
  final String status; // "Open", "In Progress", "Completed"
  final List<Applicant> applicants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String location; // Specific address details
  final List<String> imageUrls;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.wage,
    required this.postedBy,
    required this.posterName,
    required this.barangay,
    required this.status,
    required this.applicants,
    required this.createdAt,
    required this.updatedAt,
    required this.location,
    this.imageUrls = const [],
  });

  bool get isOpen => status == 'Open';

  // Factory to create from Firestore
  factory JobModel.fromMap(Map<String, dynamic> data, String id) {
    return JobModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      // Safely handle both int and double from Firestore
      wage: (data['wage'] as num?)?.toDouble() ?? 0.0,
      postedBy: data['postedBy'] ?? '',
      posterName: data['posterName'] ?? 'Unknown',
      barangay: data['barangay'] ?? '',
      status: data['status'] ?? 'Open',
      applicants: (data['applicants'] as List<dynamic>? ?? [])
          .map((app) => Applicant.fromMap(app as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'wage': wage,
      'postedBy': postedBy,
      'posterName': posterName,
      'barangay': barangay,
      'status': status,
      'applicants': applicants.map((app) => app.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
      'imageUrls': imageUrls,
    };
  }

  // CopyWith for easy updates
  JobModel copyWith({
    String? title,
    String? description,
    String? category,
    double? wage,
    String? barangay,
    String? status,
    List<Applicant>? applicants,
    DateTime? updatedAt,
    String? location,
    List<String>? imageUrls,
  }) {
    return JobModel(
      id: id, // ID never changes
      postedBy: postedBy, // Poster never changes
      posterName: posterName, // Poster name usually doesn't change contextually
      createdAt: createdAt, // Creation date never changes
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      wage: wage ?? this.wage,
      barangay: barangay ?? this.barangay,
      status: status ?? this.status,
      applicants: applicants ?? this.applicants,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}

class Applicant {
  final String userId;
  final String userName;
  final DateTime appliedAt;

  Applicant({
    required this.userId,
    required this.userName,
    required this.appliedAt,
  });

  factory Applicant.fromMap(Map<String, dynamic> data) {
    return Applicant(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'appliedAt': Timestamp.fromDate(appliedAt),
    };
  }
}
