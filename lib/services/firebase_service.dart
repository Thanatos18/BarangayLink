import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/user.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new user document in 'barangay_users' collection
  Future<void> createUserDocument(UserModel user) async {
    try {
      // Using set() with merge: true is safer in case the document partially exists
      await _db
          .collection('barangay_users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      // It is good practice to log the error or rethrow a more specific error
      throw Exception('Error creating user document: $e');
    }
  }

  // Get a user document from Firestore
  Future<UserModel?> getUserDocument(String uid) async {
    try {
      final docSnap = await _db.collection('barangay_users').doc(uid).get();

      if (docSnap.exists && docSnap.data() != null) {
        // Safely convert the data map to a UserModel
        return UserModel.fromMap(docSnap.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user document: $e');
    }
  }

  // Update a user document
  Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('barangay_users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Error updating user document: $e');
    }
  }
}
