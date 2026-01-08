import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/job.dart';
import '../models/service.dart';
import '../models/rental.dart';
import '../models/transaction.dart';
import '../models/feedback.dart';
import '../models/report.dart';
import '../models/notification.dart';
import '../models/favorite.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

// ... (existing code matches)

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

  Future<JobModel?> getJob(String jobId) async {
    try {
      final doc = await _db.collection('barangay_jobs').doc(jobId).get();
      if (doc.exists) {
        return JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting job: $e');
    }
  }

  Stream<List<JobModel>> getJobsStream(String? barangayFilter) {
    Query query =
        _db.collection('barangay_jobs').orderBy('createdAt', descending: true);

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
    String posterName,
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

      DocumentReference transRef =
          _db.collection('barangay_transactions').doc();

      Map<String, dynamic> transactionData = {
        'type': 'job_application',
        'relatedId': jobId,
        'relatedName': jobTitle,
        'initiatedBy': applicantId,
        'initiatedByName': applicantName,
        'targetUser': posterId,
        'targetUserName': posterName,
        'status': 'Pending',
        'barangay': barangay,
        'paymentStatus': 'Unpaid',
        'transactionAmount': 0,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      batch.set(transRef, transactionData);

      // Create Notification for the Poster
      DocumentReference notifRef =
          _db.collection('barangay_notifications').doc();
      NotificationModel notification = NotificationModel(
        id: notifRef.id,
        type: NotificationType.newApplication,
        title: 'New Job Application',
        message: '$applicantName applied for $jobTitle',
        relatedId: jobId,
        relatedType: 'job',
        userId: posterId,
        isRead: false,
        createdAt: DateTime.now(),
      );
      batch.set(notifRef, notification.toMap());

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

  Future<ServiceModel?> getService(String serviceId) async {
    try {
      final doc =
          await _db.collection('barangay_services').doc(serviceId).get();
      if (doc.exists) {
        return ServiceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting service: $e');
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
    required String providerName,
    required String clientId,
    required String clientName,
    required String barangay,
    required double rate,
  }) async {
    try {
      DocumentReference transRef =
          _db.collection('barangay_transactions').doc();

      Map<String, dynamic> transactionData = {
        'type': 'service_booking',
        'relatedId': serviceId,
        'relatedName': serviceName,
        'initiatedBy': clientId,
        'initiatedByName': clientName,
        'targetUser': providerId,
        'targetUserName': providerName,
        'status': 'Pending',
        'barangay': barangay,
        'paymentStatus': 'Unpaid',
        'transactionAmount': rate,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await transRef.set(transactionData);

      // Create Notification for the Provider
      await createNotification(NotificationModel(
        id: '',
        type: NotificationType.newApplication,
        title: 'New Service Booking',
        message: '$clientName booked $serviceName',
        relatedId: serviceId,
        relatedType: 'service',
        userId: providerId,
        isRead: false,
        createdAt: DateTime.now(),
      ));
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

  Future<RentalModel?> getRental(String rentalId) async {
    try {
      final doc = await _db.collection('barangay_rentals').doc(rentalId).get();
      if (doc.exists) {
        return RentalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting rental: $e');
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
    required String ownerName,
    required String renterId,
    required String renterName,
    required String barangay,
    required double rentPrice,
  }) async {
    try {
      DocumentReference transRef =
          _db.collection('barangay_transactions').doc();

      Map<String, dynamic> transactionData = {
        'type': 'rental_request',
        'relatedId': rentalId,
        'relatedName': itemName,
        'initiatedBy': renterId,
        'initiatedByName': renterName,
        'targetUser': ownerId,
        'targetUserName': ownerName,
        'status': 'Pending',
        'barangay': barangay,
        'paymentStatus': 'Unpaid',
        'transactionAmount': rentPrice,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await transRef.set(transactionData);

      // Create Notification for the Owner
      await createNotification(NotificationModel(
        id: '',
        type: NotificationType.newApplication,
        title: 'New Rental Request',
        message: '$renterName requested $itemName',
        relatedId: rentalId,
        relatedType: 'rental',
        userId: ownerId,
        isRead: false,
        createdAt: DateTime.now(),
      ));
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
    StreamController<List<TransactionModel>> controller = StreamController();
    List<TransactionModel> initiatedTransactions = [];
    List<TransactionModel> targetTransactions = [];

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

    StreamSubscription? s1;
    StreamSubscription? s2;

    void emitCombined() {
      if (controller.isClosed) return;

      final Map<String, TransactionModel> transactionsMap = {};

      for (var t in initiatedTransactions) {
        transactionsMap[t.id] = t;
      }

      for (var t in targetTransactions) {
        transactionsMap[t.id] = t;
      }

      final transactions = transactionsMap.values.toList();
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      controller.add(transactions);
    }

    s1 = initiatedQuery.listen((snapshot) {
      initiatedTransactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      emitCombined();
    });

    s2 = targetQuery.listen((snapshot) {
      targetTransactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      emitCombined();
    });

    controller.onCancel = () {
      s1?.cancel();
      s2?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// Update transaction status (Pending, Accepted, In Progress, Completed, Cancelled)
  Future<void> updateTransactionStatus(
    String transactionId,
    String newStatus,
  ) async {
    try {
      // Fetch transaction to identify parties
      final transDoc = await _db
          .collection('barangay_transactions')
          .doc(transactionId)
          .get();
      if (!transDoc.exists) return;

      final data = transDoc.data()!;
      final initiatedBy = data['initiatedBy'] as String;
      final relatedName = data['relatedName'] as String? ?? 'Item';
      final type = data['type'] as String;

      // Determine navigation target type
      String notifRelatedType = 'transaction';
      if (type == 'job_application')
        notifRelatedType = 'job';
      else if (type == 'service_booking')
        notifRelatedType = 'service';
      else if (type == 'rental_request') notifRelatedType = 'rental';

      String? notifyUserId;
      String message = 'Status updated to $newStatus';

      if (newStatus == 'Accepted') {
        notifyUserId = initiatedBy;
        message = 'Your request for $relatedName was Accepted';
      } else if (newStatus == 'In Progress') {
        notifyUserId = initiatedBy;
        message = '$relatedName is now In Progress';
      }

      await _db.collection('barangay_transactions').doc(transactionId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });

      if (notifyUserId != null) {
        await createNotification(NotificationModel(
          id: '',
          type: NotificationType.transactionUpdate,
          title: 'Transaction Update',
          message: message,
          relatedId: data['relatedId'] as String?,
          relatedType: notifRelatedType,
          userId: notifyUserId,
          isRead: false,
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      throw Exception('Error updating transaction status: $e');
    }
  }

  /// Confirm payment - sets paymentStatus to "Paid" and status to "In Progress"
  Future<void> confirmPayment(String transactionId) async {
    try {
      // Fetch transaction to identify provider
      final transDoc = await _db
          .collection('barangay_transactions')
          .doc(transactionId)
          .get();
      if (!transDoc.exists) throw Exception('Transaction not found');

      final data = transDoc.data()!;
      final targetUser = data['targetUser'] as String;
      final relatedName = data['relatedName'] as String? ?? 'Transaction';
      final type = data['type'] as String;

      String notifRelatedType = 'transaction';
      if (type == 'job_application')
        notifRelatedType = 'job';
      else if (type == 'service_booking')
        notifRelatedType = 'service';
      else if (type == 'rental_request') notifRelatedType = 'rental';

      await _db.collection('barangay_transactions').doc(transactionId).update({
        'paymentStatus': 'Paid',
        'status': 'In Progress',
        'updatedAt': Timestamp.now(),
      });

      // Notify Provider
      await createNotification(NotificationModel(
        id: '',
        type: NotificationType.paymentReceived,
        title: 'Payment Received',
        message: 'Payment confirmed for $relatedName',
        relatedId: data['relatedId'] as String?,
        relatedType: notifRelatedType,
        userId: targetUser,
        isRead: false,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      throw Exception('Error confirming payment: $e');
    }
  }

  /// Complete transaction - sets status to "Completed" and adds completedAt timestamp
  Future<void> completeTransaction(String transactionId) async {
    try {
      // Fetch transaction to identify client
      final transDoc = await _db
          .collection('barangay_transactions')
          .doc(transactionId)
          .get();
      if (!transDoc.exists) throw Exception('Transaction not found');

      final data = transDoc.data()!;
      final initiatedBy = data['initiatedBy'] as String;
      final relatedName = data['relatedName'] as String? ?? 'Transaction';
      final type = data['type'] as String;

      String notifRelatedType = 'transaction';
      if (type == 'job_application')
        notifRelatedType = 'job';
      else if (type == 'service_booking')
        notifRelatedType = 'service';
      else if (type == 'rental_request') notifRelatedType = 'rental';

      await _db.collection('barangay_transactions').doc(transactionId).update({
        'status': 'Completed',
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Notify Client
      await createNotification(NotificationModel(
        id: '',
        type: NotificationType.transactionUpdate,
        title: 'Transaction Completed',
        message: '$relatedName has been marked as completed',
        relatedId: data['relatedId'] as String?,
        relatedType: notifRelatedType,
        userId: initiatedBy,
        isRead: false,
        createdAt: DateTime.now(),
      ));
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

      final initiatedTransactionsCount = await _db
          .collection('barangay_transactions')
          .where('initiatedBy', isEqualTo: userId)
          .where('status', isEqualTo: 'Completed')
          .count()
          .get();

      final targetTransactionsCount = await _db
          .collection('barangay_transactions')
          .where('targetUser', isEqualTo: userId)
          .where('status', isEqualTo: 'Completed')
          .count()
          .get();

      final totalTransactions = (initiatedTransactionsCount.count ?? 0) +
          (targetTransactionsCount.count ?? 0);

      return {
        'jobs': jobsCount.count ?? 0,
        'services': servicesCount.count ?? 0,
        'rentals': rentalsCount.count ?? 0,
        'transactions': totalTransactions,
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
      Query query =
          _db.collection('barangay_users').orderBy('name').limit(limit);

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
      final servicesCount =
          await _db.collection('barangay_services').count().get();
      final rentalsCount =
          await _db.collection('barangay_rentals').count().get();
      final transactionsCount =
          await _db.collection('barangay_transactions').count().get();
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
      // Use doc() to generate ID, then set() to ensure ID is consistent
      final docRef = _db.collection('barangay_notifications').doc();
      final newNotification = notification.copyWith(id: docRef.id);
      await docRef.set(newNotification.toMap());
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

  /// Delete a single notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db
          .collection('barangay_notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  /// Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final batch = _db.batch();
      final snapshot = await _db
          .collection('barangay_notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error clearing all notifications: $e');
    }
  }

  // --- Favorites ---

  /// Toggle Favorite
  Future<void> toggleFavorite(FavoriteModel favorite) async {
    try {
      final querySnapshot = await _db
          .collection('barangay_favorites')
          .where('userId', isEqualTo: favorite.userId)
          .where('itemId', isEqualTo: favorite.itemId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Already exists, remove it
        await querySnapshot.docs.first.reference.delete();
      } else {
        // Doesn't exist, add it
        await _db.collection('barangay_favorites').add(favorite.toMap());
      }
    } catch (e) {
      throw Exception('Error toggling favorite: $e');
    }
  }

  /// Stream user's favorites
  Stream<List<FavoriteModel>> getUserFavoritesStream(String userId) {
    return _db
        .collection('barangay_favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FavoriteModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Check if item is favorited by user
  Future<bool> isFavorite(String userId, String itemId) async {
    try {
      final snapshot = await _db
          .collection('barangay_favorites')
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
