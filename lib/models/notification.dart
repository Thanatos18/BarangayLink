import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types for BarangayLink
class NotificationType {
  static const String transactionUpdate = 'transaction_update';
  static const String newApplication = 'new_application';
  static const String paymentReceived = 'payment_received';
  static const String feedbackReceived = 'feedback_received';
  static const String reportResolved = 'report_resolved';
}

/// Notification model for in-app notifications.
class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? relatedId;
  final String? relatedType; // 'transaction', 'job', 'service', 'rental'
  final String userId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.relatedType,
    required this.userId,
    this.isRead = false,
    required this.createdAt,
  });

  // --- Type Getters ---

  bool get isTransactionUpdate => type == NotificationType.transactionUpdate;
  bool get isNewApplication => type == NotificationType.newApplication;
  bool get isPaymentReceived => type == NotificationType.paymentReceived;
  bool get isFeedbackReceived => type == NotificationType.feedbackReceived;

  /// Get icon based on notification type
  String get iconName {
    switch (type) {
      case NotificationType.transactionUpdate:
        return 'receipt';
      case NotificationType.newApplication:
        return 'person_add';
      case NotificationType.paymentReceived:
        return 'payment';
      case NotificationType.feedbackReceived:
        return 'star';
      case NotificationType.reportResolved:
        return 'flag';
      default:
        return 'notifications';
    }
  }

  /// Get color name based on type
  String get colorName {
    switch (type) {
      case NotificationType.transactionUpdate:
        return 'blue';
      case NotificationType.newApplication:
        return 'green';
      case NotificationType.paymentReceived:
        return 'orange';
      case NotificationType.feedbackReceived:
        return 'yellow';
      case NotificationType.reportResolved:
        return 'red';
      default:
        return 'grey';
    }
  }

  // --- Serialization ---

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'message': message,
      'relatedId': relatedId,
      'relatedType': relatedType,
      'userId': userId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      relatedId: map['relatedId'],
      relatedType: map['relatedType'],
      userId: map['userId'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({String? id, bool? isRead}) {
    return NotificationModel(
      id: id ?? this.id,
      type: type,
      title: title,
      message: message,
      relatedId: relatedId,
      relatedType: relatedType,
      userId: userId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, isRead: $isRead)';
  }
}
