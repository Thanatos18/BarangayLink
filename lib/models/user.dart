import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String barangay;
  final String role;
  final String? profileImageUrl;
  final String contactNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isBanned;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.barangay,
    this.role = 'user', // Default role
    this.profileImageUrl,
    required this.contactNumber,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true, // Default active
    this.isBanned = false, // Default not banned
    this.pushNotificationsEnabled = true, // Default enabled
    this.emailNotificationsEnabled = true, // Default enabled
  });

  // Method to check if user is admin
  bool get isAdmin => role == 'admin';

  // Method to check if admin can moderate a specific barangay
  bool canModerateBarangay(String targetBarangay) {
    if (!isAdmin) return false;
    // In the future, you can check specific assignments here.
    // For now, admins have global access.
    return true;
  }

  // Convert UserModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'barangay': barangay,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'contactNumber': contactNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'isBanned': isBanned,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
    };
  }

  // Create a UserModel from a Firestore document snapshot
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      barangay: map['barangay'] ?? '',
      role: map['role'] ?? 'user',
      profileImageUrl: map['profileImageUrl'],
      contactNumber: map['contactNumber'] ?? '',
      // Handle potential nulls for timestamps safely
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      isBanned: map['isBanned'] ?? false,
      pushNotificationsEnabled: map['pushNotificationsEnabled'] ?? true,
      emailNotificationsEnabled: map['emailNotificationsEnabled'] ?? true,
    );
  }

  // CopyWith method - Essential for updating state (e.g., Edit Profile)
  UserModel copyWith({
    String? name,
    String? barangay,
    String? role,
    String? profileImageUrl,
    String? contactNumber,
    DateTime? updatedAt,
    bool? isActive,
    bool? isBanned,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
  }) {
    return UserModel(
      uid: uid, // ID never changes
      email: email, // Email usually doesn't change here
      createdAt: createdAt, // Created date never changes
      name: name ?? this.name,
      barangay: barangay ?? this.barangay,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      contactNumber: contactNumber ?? this.contactNumber,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isBanned: isBanned ?? this.isBanned,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
    );
  }
}
