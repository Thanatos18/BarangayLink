import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/user.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/firebase_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      // Optimization: Only fetch if we don't already have the data for this user
      if (_currentUser?.uid != user.uid) {
        await fetchUserProfile(user.uid);
      }
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.login(email: email, password: password);
      // No need to fetchUserProfile here; _onAuthStateChanged will handle it automatically!
    } catch (e) {
      _setError(e.toString());
      rethrow; // Rethrow so the UI knows exactly what failed
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String contactNumber,
    required String barangay,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        contactNumber: contactNumber,
        barangay: barangay,
      );
      // Again, _onAuthStateChanged will handle the profile fetching automatically
    } catch (e) {
      _setError(e.toString());
      rethrow; // Important: Let the UI handle specific error codes
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchUserProfile(String uid) async {
    _setLoading(true);
    try {
      _currentUser = await _firebaseService.getUserDocument(uid);
      notifyListeners(); // Notify UI that user data is ready
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// Refresh current user data from Firestore
  Future<void> refreshUser() async {
    if (_currentUser != null) {
      await fetchUserProfile(_currentUser!.uid);
    }
  }

  Future<void> sendPasswordResetEmail() async {
    if (_currentUser == null) return;
    try {
      await _authService.resetPassword(_currentUser!.email);
    } catch (e) {
      rethrow;
    }
  }
}
