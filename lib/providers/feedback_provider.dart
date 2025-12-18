import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/feedback.dart';
import '../services/firebase_service.dart';

/// Provider for managing feedback state and user ratings.
class FeedbackProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // --- State ---
  List<FeedbackModel> _userFeedback = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<String, int> _userStats = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _sortBy = 'newest'; // 'newest', 'highest', 'lowest'

  // Stream subscription
  StreamSubscription<List<FeedbackModel>>? _feedbackSubscription;
  String? _currentUserId;

  // --- Getters ---

  List<FeedbackModel> get userFeedback => _sortedFeedback;
  double get averageRating => _averageRating;
  int get totalReviews => _totalReviews;
  Map<String, int> get userStats => _userStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get sortBy => _sortBy;

  /// Returns feedback sorted according to current sort setting
  List<FeedbackModel> get _sortedFeedback {
    List<FeedbackModel> sorted = List.from(_userFeedback);

    switch (_sortBy) {
      case 'highest':
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowest':
        sorted.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case 'newest':
      default:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return sorted;
  }

  /// Get recent feedback (last 3)
  List<FeedbackModel> get recentFeedback {
    final sorted = List<FeedbackModel>.from(_userFeedback);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(3).toList();
  }

  // --- Feedback Stream Methods ---

  /// Start listening to user's received feedback
  void startListening(String userId) {
    if (_currentUserId == userId && _feedbackSubscription != null) {
      return;
    }

    stopListening();
    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _feedbackSubscription = _firebaseService
        .getUserFeedbackStream(userId)
        .listen(
          (feedback) {
            _userFeedback = feedback;
            _totalReviews = feedback.length;
            _calculateLocalAverage();
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Error loading feedback: $error';
            _isLoading = false;
            notifyListeners();
          },
        );

    // Also fetch rating and stats
    _fetchRatingAndStats(userId);
  }

  /// Stop listening to feedback updates
  void stopListening() {
    _feedbackSubscription?.cancel();
    _feedbackSubscription = null;
    _currentUserId = null;
  }

  /// Fetch rating and stats from Firebase
  Future<void> _fetchRatingAndStats(String userId) async {
    try {
      final ratingData = await _firebaseService.calculateAverageRating(userId);
      _averageRating = ratingData['average'] as double;
      _totalReviews = ratingData['count'] as int;

      final stats = await _firebaseService.getUserStats(userId);
      _userStats = stats;

      notifyListeners();
    } catch (e) {
      // Silently fail - feedback stream will still work
      debugPrint('Error fetching rating/stats: $e');
    }
  }

  /// Calculate average from local feedback list
  void _calculateLocalAverage() {
    if (_userFeedback.isEmpty) {
      _averageRating = 0.0;
      return;
    }

    double total = 0;
    for (var feedback in _userFeedback) {
      total += feedback.rating;
    }
    _averageRating = total / _userFeedback.length;
  }

  // --- Sort Methods ---

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  // --- Submit Feedback ---

  /// Submit feedback for a completed transaction
  Future<bool> submitFeedback({
    required int rating,
    required String review,
    required String transactionId,
    required String reviewedBy,
    required String? reviewedByName,
    required String reviewedUser,
    required String? reviewedUserName,
    required String barangay,
  }) async {
    try {
      final feedback = FeedbackModel(
        id: '', // Will be assigned by Firestore
        rating: rating,
        review: review,
        transactionId: transactionId,
        reviewedBy: reviewedBy,
        reviewedByName: reviewedByName,
        reviewedUser: reviewedUser,
        reviewedUserName: reviewedUserName,
        barangay: barangay,
        createdAt: DateTime.now(),
      );

      await _firebaseService.submitFeedback(feedback);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit feedback: $e';
      notifyListeners();
      return false;
    }
  }

  // --- Utility Methods ---

  /// Refresh rating and stats for a user
  Future<void> refreshUserData(String userId) async {
    await _fetchRatingAndStats(userId);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
