import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Stream to listen for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase User
  User? get currentUser => _auth.currentUser;

  // Register with email, password, and create user document
  Future<User?> register({
    required String name,
    required String email,
    required String password,
    required String contactNumber,
    required String barangay,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // 2. Create UserModel
        UserModel newUser = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          barangay: barangay,
          contactNumber: contactNumber,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 3. Save to Firestore via FirebaseService
        await _firebaseService.createUserDocument(newUser);
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Throw the specific Firebase exception so UI can handle specific error codes
      // e.g. if (e.code == 'weak-password') ...
      throw e;
    } catch (e) {
      throw Exception('An unknown error occurred: $e');
    }
  }

  // Login with email and password
  Future<User?> login({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e; // Pass the specific error up to the UI
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error logging out: $e');
    }
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }
}
