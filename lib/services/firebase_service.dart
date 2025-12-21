import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/job.dart';
import '../models/service.dart';
import '../models/rental.dart';
import '../models/transaction.dart';
import '../models/feedback.dart';
import '../models/report.dart';
import '../models/notification.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USER METHODS ---

  Future<void> createUserDocument(UserModel user) async {
    try {
      await _db.collection('barangay_users').doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Error creating user document: $e');
    }
  }

  Future<UserModel?> getUserDocument(String uid) async {
    try {
      final docSnap = await _db.collection('barangay_users').doc(uid).get();
      if (docSnap.exists) {
        return UserModel.fromMap(docSnap.data()!, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user document: $e');
    }
  }

  // --- JOB METHODS ---

  Future<void> createJob(JobModel job) async {
    try {
      DocumentReference docRef = _db.collection('barangay_jobs').doc();
      await docRef.set(job.toMap());
    } catch (e) {
      throw Exception('Error creating job: $e');
    }
  }

  Stream<List<JobModel>> getJobsStream(String? barangayFilter) {
    Query query = _db
        .collection('barangay_jobs')
        .orderBy('createdAt', descending: true);

    if (barangayFilter != null && barangayFilter != 'All Tagum City') {
      query = query.where('barangay', isEqualTo: barangayFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    try {
      await _db.collection('barangay_jobs').doc(jobId).update(data);
    } catch (e) {
      throw Exception('Error updating job: $e');
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      await _db.collection('barangay_jobs').doc(jobId).delete();
    } catch (e) {
      throw Exception('Error deleting job: $e');
    }
  }

  Future<void> applyToJob(
    String jobId,
    String jobTitle,
    String posterId,
    String applicantId,
    String applicantName,
    String barangay,
  ) async {
    WriteBatch batch = _db.batch();

    try {
      DocumentReference jobRef = _db.collection('barangay_jobs').doc(jobId);

      Applicant newApplicant = Applicant(
        userId: applicantId,
        userName: applicantName,
        appliedAt: DateTime.now(),
      );

      batch.update(jobRef, {
        'applicants': FieldValue.arrayUnion([newApplicant.toMap()]),
      });

      DocumentReference transRef = _db
          .collection('barangay_transactions')
          .doc();

      Map<String, dynamic> transactionData = {
        'type': 'job_application',
        'relatedId': jobId,
        'relatedName': jobTitle,
        'initiatedBy': applicantId,
        'targetUser': posterId,
        'status': 'Pending',
        'barangay': barangay,
        'paymentStatus': 'Unpaid',
        'transactionAmount': 0,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      batch.set(transRef, transactionData);
      await batch.commit();
    } catch (e) {
      throw Exception('Error applying to job: $e');
    }
  }

  // --- SERVICE METHODS ---

  Future<void> createService(ServiceModel service) async {
    try {
      DocumentReference docRef = _db.collection('barangay_services').doc();
      await docRef.set(service.toMap());
    } catch (e) {
      throw Exception('Error creating service: $e');
    }
  }

  Stream<List<ServiceModel>> getServicesStream(String? barangayFilter) {
    Query query = _db
        .collection('barangay_services')
        .orderBy('createdAt', descending: true);

    if (barangayFilter != null && barangayFilter != 'All Tagum City') {
      query = query.where('barangay', isEqualTo: barangayFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ServiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> updateService(
    String serviceId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection('barangay_services').doc(serviceId).update(data);
    } catch (e) {
      throw Exception('Error updating service: $e');
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _db.collection('barangay_services').doc(serviceId).delete();
    } catch (e) {
      throw Exception('Error deleting service: $e');
    }
  }

  Future<void> bookService({
    required String serviceId,
    required String serviceName,
    required String providerId,
    required String clientId,
    required String clientName,
    required String barangay,
    required double rate,
  }) async {
    try {
      DocumentReference transRef = _db
          .collection('barangay_transactions')
          .doc();

      Map<String, dynamic> transactionData = {
        'type': 'service_booking',
        'relatedId': serviceId,
        'relatedName': serviceName,
        'initiatedBy': clientId,
        'initiatedByName': clientName,
        'targetUser': providerId,
        'status': 'Pending',
        'barangay': barangay,
        'paymentStatus': 'Unpaid',
        'transactionAmount': rate,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await transRef.set(transactionData);
    } catch (e) {
      throw Exception('Error booking service: $e');
    }
  }

  // --- RENTAL METHODS ---

  Future<void> createRental(RentalModel rental) async {
    try {
      DocumentReference docRef = _db.collection('barangay_rentals').doc();
      await docRef.set(rental.toMap());
    } catch (e) {
      throw Exception('Error creating rental: $e');
    }
  }

  Stream<List<RentalModel>> getRentalsStream(String? barangayFilter) {
    Query query = _db
        .collection('barangay_rentals')
        .orderBy('createdAt', descending: true);

    if (barangayFilter != null && barangayFilter != 'All Tagum City') {
      query = query.where('barangay', isEqualTo: barangayFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RentalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> updateRental(String rentalId, Map<String, dynamic> data) async {
    try {
      await _db.collection('barangay_rentals').doc(rentalId).update(data);
    } catch (e) {
      throw Exception('Error updating rental: $e');
    }
  }

  Future<void> deleteRental(String rentalId) async {
    try {
      await _db.collection('barangay_rentals').doc(rentalId).delete();
    } catch (e) {
      throw Exception('Error deleting rental: $e');
    }
  }

  Future<void> requestRental({
    required String rentalId,
    required String itemName,
    required String ownerId,
    required String renterId,
    required String renterName,
    required String barangay,
    required double rentPrice,
  }) async {
    try {
      DocumentReference transRef = _db
          .collection('barangay_transactions')
          .doc();

      Map<String, dynamic> transactionData = {
        'type': 'rental_request',
        'relatedId': rentalId,
        'relatedName': itemName,
        'initiatedBy': renterId,
        'initiatedByName': renterName,
        'targetUser': ownerId,
        'status': 'Pending',
        'barangay': barangay,
        'paymentStatus': 'Unpaid',
        'transactionAmount': rentPrice,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await transRef.set(transactionData);
    } catch (e) {
      throw Exception('Error requesting rental: $e');
    }
  }

  // --- TRANSACTION METHODS ---

  /// Fetch a single transaction by ID
  Future<TransactionModel?> getTransaction(String transactionId) async {
    try {
      final docSnap = await _db
          .collection('barangay_transactions')
          .doc(transactionId)
          .get();
      if (docSnap.exists) {
        return TransactionModel.fromMap(docSnap.data()!, docSnap.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting transaction: $e');
    }
  }

  /// Stream all transactions where the user is either initiator or target.
  /// This merges two queries into a single stream.
  Stream<List<TransactionModel>> getUserTransactionsStream(String userId) {
    // Query for transactions initiated by user
    final initiatedQuery = _db
        .collection('barangay_transactions')
        .where('initiatedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    // Query for transactions targeting user
    final targetQuery = _db
        .collection('barangay_transactions')
        .where('targetUser', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    // Combine both streams
    return initiatedQuery.asyncMap((initiatedSnapshot) async {
      final targetSnapshot = await targetQuery.first;

      // Collect all transactions, using a Set to avoid duplicates
      final Map<String, TransactionModel> transactionsMap = {};

      for (var doc in initiatedSnapshot.docs) {
        transactionsMap[doc.id] = TransactionModel.fromMap(doc.data(), doc.id);
      }

      for (var doc in targetSnapshot.docs) {
        transactionsMap[doc.id] = TransactionModel.fromMap(doc.data(), doc.id);
      }

      // Sort by createdAt descending
      final transactions = transactionsMap.values.toList();
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return transactions;
    });
  }

  /// Update transaction status (Pending, Accepted, In Progress, Completed, Cancelled)
  Future<void> updateTransactionStatus(
    String transactionId,
    String newStatus,
  ) async {
    try {
      await _db.collection('barangay_transactions').doc(transactionId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error updating transaction status: $e');
    }
  }

  /// Confirm payment - sets paymentStatus to "Paid" and status to "In Progress"
  Future<void> confirmPayment(String transactionId) async {
    try {
      await _db.collection('barangay_transactions').doc(transactionId).update({
        'paymentStatus': 'Paid',
        'status': 'In Progress',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error confirming payment: $e');
    }
  }

  /// Complete transaction - sets status to "Completed" and adds completedAt timestamp
  Future<void> completeTransaction(String transactionId) async {
    try {
      await _db.collection('barangay_transactions').doc(transactionId).update({
        'status': 'Completed',
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error completing transaction: $e');
    }
  }

  /// Get user name by UID (for displaying other party's name in transactions)
  Future<String> getUserName(String userId) async {
    try {
      final userDoc = await getUserDocument(userId);
      return userDoc?.name ?? 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }

  // --- FEEDBACK METHODS (Phase 7) ---

  /// Submit feedback for a completed transaction
  Future<void> submitFeedback(FeedbackModel feedback) async {
    try {
      DocumentReference docRef = _db.collection('barangay_feedback').doc();
      await docRef.set(feedback.toMap());
    } catch (e) {
      throw Exception('Error submitting feedback: $e');
    }
  }

  /// Stream all feedback received by a user
  Stream<List<FeedbackModel>> getUserFeedbackStream(String userId) {
    return _db
        .collection('barangay_feedback')
        .where('reviewedUser', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return FeedbackModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Calculate average rating for a user
  Future<Map<String, dynamic>> calculateAverageRating(String userId) async {
    try {
      final snapshot = await _db
          .collection('barangay_feedback')
          .where('reviewedUser', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'average': 0.0, 'count': 0};
      }

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['rating'] ?? 0).toDouble();
      }

      return {
        'average': total / snapshot.docs.length,
        'count': snapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Error calculating average rating: $e');
    }
  }

  /// Get user statistics (jobs, services, rentals, transactions count)
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final jobsCount = await _db
          .collection('barangay_jobs')
          .where('postedBy', isEqualTo: userId)
          .count()
          .get();

      final servicesCount = await _db
          .collection('barangay_services')
          .where('providerId', isEqualTo: userId)
          .count()
          .get();

      final rentalsCount = await _db
          .collection('barangay_rentals')
          .where('ownerId', isEqualTo: userId)
          .count()
          .get();

      final transactionsCount = await _db
          .collection('barangay_transactions')
          .where('initiatedBy', isEqualTo: userId)
          .count()
          .get();

      return {
        'jobs': jobsCount.count ?? 0,
        'services': servicesCount.count ?? 0,
        'rentals': rentalsCount.count ?? 0,
        'transactions': transactionsCount.count ?? 0,
      };
    } catch (e) {
      throw Exception('Error getting user stats: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _db.collection('barangay_users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  // --- ADMIN METHODS (Phase 8) ---

  /// Get all users with optional pagination
  Future<List<UserModel>> getAllUsers({
    int limit = 50,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = _db
          .collection('barangay_users')
          .orderBy('name')
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  /// Update user ban status
  Future<void> updateUserBanStatus(String uid, bool isBanned) async {
    try {
      await _db.collection('barangay_users').doc(uid).update({
        'isBanned': isBanned,
        'bannedAt': isBanned ? Timestamp.now() : null,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error updating user ban status: $e');
    }
  }

  /// Submit a report
  Future<void> submitReport(ReportModel report) async {
    try {
      await _db.collection('barangay_reports').add(report.toMap());
    } catch (e) {
      throw Exception('Error submitting report: $e');
    }
  }

  /// Stream all pending reports
  Stream<List<ReportModel>> getReportsStream() {
    return _db
        .collection('barangay_reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ReportModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Resolve a report
  Future<void> resolveReport(
    String reportId,
    String resolution,
    String resolvedBy,
  ) async {
    try {
      await _db.collection('barangay_reports').doc(reportId).update({
        'status': 'resolved',
        'resolution': resolution,
        'resolvedBy': resolvedBy,
        'resolvedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error resolving report: $e');
    }
  }

  /// Dismiss a report
  Future<void> dismissReport(String reportId, String resolvedBy) async {
    try {
      await _db.collection('barangay_reports').doc(reportId).update({
        'status': 'dismissed',
        'resolvedBy': resolvedBy,
        'resolvedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error dismissing report: $e');
    }
  }

  /// Delete an item (for content moderation)
  Future<void> deleteItem(String collection, String itemId) async {
    try {
      await _db.collection(collection).doc(itemId).delete();
    } catch (e) {
      throw Exception('Error deleting item: $e');
    }
  }

  /// Get admin dashboard statistics
  Future<Map<String, int>> getAdminStats() async {
    try {
      final usersCount = await _db.collection('barangay_users').count().get();
      final jobsCount = await _db.collection('barangay_jobs').count().get();
      final servicesCount = await _db
          .collection('barangay_services')
          .count()
          .get();
      final rentalsCount = await _db
          .collection('barangay_rentals')
          .count()
          .get();
      final transactionsCount = await _db
          .collection('barangay_transactions')
          .count()
          .get();
      final reportsCount = await _db
          .collection('barangay_reports')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      return {
        'users': usersCount.count ?? 0,
        'jobs': jobsCount.count ?? 0,
        'services': servicesCount.count ?? 0,
        'rentals': rentalsCount.count ?? 0,
        'transactions': transactionsCount.count ?? 0,
        'pendingReports': reportsCount.count ?? 0,
      };
    } catch (e) {
      throw Exception('Error getting admin stats: $e');
    }
  }

  /// Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Search by name (starts with)
      final nameSnapshot = await _db
          .collection('barangay_users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return nameSnapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  // --- NOTIFICATION METHODS (Phase 9) ---

  /// Create a notification for a user
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _db.collection('barangay_notifications').add(notification.toMap());
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  /// Stream user's notifications
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _db
        .collection('barangay_notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return NotificationModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _db.collection('barangay_notifications').doc(notificationId).update(
        {'isRead': true},
      );
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _db.batch();
      final snapshot = await _db
          .collection('barangay_notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  /// Get unread notification count for a user
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final count = await _db
          .collection('barangay_notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      return count.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
