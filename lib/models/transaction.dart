import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction model for tracking job applications, service bookings, and rental requests.
/// Each transaction links an initiator (applicant/client/renter) to a target user (poster/provider/owner).
class TransactionModel {
  final String id;
  final String type; // 'job_application', 'service_booking', 'rental_request'
  final String relatedId; // ID of job/service/rental
  final String relatedName; // Name/title of the related item
  final String initiatedBy; // UID of the user who initiated
  final String? initiatedByName; // Name of initiator
  final String targetUser; // UID of the target user (poster/provider/owner)
  final String? targetUserName; // Name of target user
  final String status; // 'Pending', 'Accepted', 'In Progress', 'Completed', 'Cancelled'
  final double transactionAmount;
  final String paymentStatus; // 'Unpaid', 'Paid'
  final String barangay;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.relatedId,
    required this.relatedName,
    required this.initiatedBy,
    this.initiatedByName,
    required this.targetUser,
    this.targetUserName,
    required this.status,
    required this.transactionAmount,
    required this.paymentStatus,
    required this.barangay,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  // --- Status Getters ---

  bool get isPending => status == 'Pending';
  bool get isAccepted => status == 'Accepted';
  bool get isInProgress => status == 'In Progress';
  bool get isCompleted => status == 'Completed';
  bool get isCancelled => status == 'Cancelled';
  bool get isPaid => paymentStatus == 'Paid';

  // --- Type Getters ---

  bool get isJobApplication => type == 'job_application';
  bool get isServiceBooking => type == 'service_booking';
  bool get isRentalRequest => type == 'rental_request';

  /// Returns a human-readable type label
  String get typeLabel {
    switch (type) {
      case 'job_application':
        return 'Job Application';
      case 'service_booking':
        return 'Service Booking';
      case 'rental_request':
        return 'Rental Request';
      default:
        return type;
    }
  }

  /// Returns appropriate icon name for the transaction type
  String get typeIconName {
    switch (type) {
      case 'job_application':
        return 'work';
      case 'service_booking':
        return 'build';
      case 'rental_request':
        return 'handyman';
      default:
        return 'receipt';
    }
  }

  // --- Serialization ---

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'relatedId': relatedId,
      'relatedName': relatedName,
      'initiatedBy': initiatedBy,
      'initiatedByName': initiatedByName,
      'targetUser': targetUser,
      'targetUserName': targetUserName,
      'status': status,
      'transactionAmount': transactionAmount,
      'paymentStatus': paymentStatus,
      'barangay': barangay,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      type: map['type'] ?? '',
      relatedId: map['relatedId'] ?? '',
      relatedName: map['relatedName'] ?? '',
      initiatedBy: map['initiatedBy'] ?? '',
      initiatedByName: map['initiatedByName'],
      targetUser: map['targetUser'] ?? '',
      targetUserName: map['targetUserName'],
      status: map['status'] ?? 'Pending',
      transactionAmount: (map['transactionAmount'] ?? 0).toDouble(),
      paymentStatus: map['paymentStatus'] ?? 'Unpaid',
      barangay: map['barangay'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  // --- CopyWith for Immutable Updates ---

  TransactionModel copyWith({
    String? status,
    String? paymentStatus,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? initiatedByName,
    String? targetUserName,
  }) {
    return TransactionModel(
      id: id,
      type: type,
      relatedId: relatedId,
      relatedName: relatedName,
      initiatedBy: initiatedBy,
      initiatedByName: initiatedByName ?? this.initiatedByName,
      targetUser: targetUser,
      targetUserName: targetUserName ?? this.targetUserName,
      status: status ?? this.status,
      transactionAmount: transactionAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      barangay: barangay,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: $type, status: $status, amount: $transactionAmount)';
  }
}
