import 'package:cloud_firestore/cloud_firestore.dart';

/// Feedback model for storing user ratings and reviews after completed transactions.
class FeedbackModel {
  final String id;
  final int rating; // 1-5 stars
  final String review; // Max 500 characters
  final String transactionId;
  final String reviewedBy; // UID of the reviewer
  final String? reviewedByName; // Name of the reviewer
  final String reviewedUser; // UID of the user being reviewed
  final String? reviewedUserName; // Name of the user being reviewed
  final String barangay;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.rating,
    required this.review,
    required this.transactionId,
    required this.reviewedBy,
    this.reviewedByName,
    required this.reviewedUser,
    this.reviewedUserName,
    required this.barangay,
    required this.createdAt,
  });

  // --- Rating Getters ---

  /// Rating is positive (4-5 stars)
  bool get isPositive => rating >= 4;

  /// Rating is neutral (3 stars)
  bool get isNeutral => rating == 3;

  /// Rating is negative (1-2 stars)
  bool get isNegative => rating <= 2;

  /// Returns emoji based on rating
  String get ratingEmoji {
    if (isPositive) return '😊';
    if (isNeutral) return '😐';
    return '😞';
  }

  /// Returns color name for styling
  String get ratingColorName {
    if (isPositive) return 'green';
    if (isNeutral) return 'orange';
    return 'red';
  }

  // --- Serialization ---

  Map<String, dynamic> toMap() {
    return {
      'rating': rating,
      'review': review,
      'transactionId': transactionId,
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'reviewedUser': reviewedUser,
      'reviewedUserName': reviewedUserName,
      'barangay': barangay,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      rating: map['rating'] ?? 0,
      review: map['review'] ?? '',
      transactionId: map['transactionId'] ?? '',
      reviewedBy: map['reviewedBy'] ?? '',
      reviewedByName: map['reviewedByName'],
      reviewedUser: map['reviewedUser'] ?? '',
      reviewedUserName: map['reviewedUserName'],
      barangay: map['barangay'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'FeedbackModel(id: $id, rating: $rating, reviewedUser: $reviewedUser)';
  }
}
