import 'package:cloud_firestore/cloud_firestore.dart';

/// Report model for flagging inappropriate content.
class ReportModel {
  final String id;
  final String reportedItemId;
  final String reportedItemType; // 'job', 'service', 'rental', 'user'
  final String reportedItemTitle;
  final String reportedBy;
  final String? reportedByName;
  final String reason;
  final String? additionalDetails;
  final String status; // 'pending', 'reviewed', 'resolved', 'dismissed'
  final String? resolvedBy;
  final String? resolution;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  ReportModel({
    required this.id,
    required this.reportedItemId,
    required this.reportedItemType,
    required this.reportedItemTitle,
    required this.reportedBy,
    this.reportedByName,
    required this.reason,
    this.additionalDetails,
    required this.status,
    this.resolvedBy,
    this.resolution,
    required this.createdAt,
    this.resolvedAt,
  });

  // --- Status Getters ---

  bool get isPending => status == 'pending';
  bool get isReviewed => status == 'reviewed';
  bool get isResolved => status == 'resolved';
  bool get isDismissed => status == 'dismissed';

  // --- Type Getters ---

  bool get isJobReport => reportedItemType == 'job';
  bool get isServiceReport => reportedItemType == 'service';
  bool get isRentalReport => reportedItemType == 'rental';
  bool get isUserReport => reportedItemType == 'user';

  String get typeLabel {
    switch (reportedItemType) {
      case 'job':
        return 'Job Listing';
      case 'service':
        return 'Service';
      case 'rental':
        return 'Rental';
      case 'user':
        return 'User';
      default:
        return 'Item';
    }
  }

  // --- Serialization ---

  Map<String, dynamic> toMap() {
    return {
      'reportedItemId': reportedItemId,
      'reportedItemType': reportedItemType,
      'reportedItemTitle': reportedItemTitle,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'reason': reason,
      'additionalDetails': additionalDetails,
      'status': status,
      'resolvedBy': resolvedBy,
      'resolution': resolution,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      id: id,
      reportedItemId: map['reportedItemId'] ?? '',
      reportedItemType: map['reportedItemType'] ?? '',
      reportedItemTitle: map['reportedItemTitle'] ?? '',
      reportedBy: map['reportedBy'] ?? '',
      reportedByName: map['reportedByName'],
      reason: map['reason'] ?? '',
      additionalDetails: map['additionalDetails'],
      status: map['status'] ?? 'pending',
      resolvedBy: map['resolvedBy'],
      resolution: map['resolution'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  ReportModel copyWith({
    String? status,
    String? resolvedBy,
    String? resolution,
    DateTime? resolvedAt,
  }) {
    return ReportModel(
      id: id,
      reportedItemId: reportedItemId,
      reportedItemType: reportedItemType,
      reportedItemTitle: reportedItemTitle,
      reportedBy: reportedBy,
      reportedByName: reportedByName,
      reason: reason,
      additionalDetails: additionalDetails,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolution: resolution ?? this.resolution,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  String toString() {
    return 'ReportModel(id: $id, type: $reportedItemType, status: $status)';
  }
}

/// Common report reasons
class ReportReasons {
  static const List<String> reasons = [
    'Spam or misleading',
    'Inappropriate content',
    'Harassment or bullying',
    'Fraud or scam',
    'False information',
    'Duplicate listing',
    'Wrong category',
    'Other',
  ];
}
