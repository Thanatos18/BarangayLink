import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/job.dart';
import '../models/service.dart';
import '../models/rental.dart';

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

      DocumentReference transRef = _db.collection('barangay_transactions').doc();

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

  Future<void> updateService(String serviceId, Map<String, dynamic> data) async {
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
      DocumentReference transRef = _db.collection('barangay_transactions').doc();

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
      DocumentReference transRef = _db.collection('barangay_transactions').doc();

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
}
