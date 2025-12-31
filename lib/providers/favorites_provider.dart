import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/favorite.dart';
import '../services/firebase_service.dart';

/// Provider for managing user's favorites.
class FavoritesProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // --- State ---
  List<FavoriteModel> _favorites = [];
  Set<String> _favoriteIds = {}; // Quick lookup
  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscription
  StreamSubscription<List<FavoriteModel>>? _favoritesSubscription;
  String? _currentUserId;

  // --- Getters ---

  List<FavoriteModel> get favorites => _favorites;
  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get favorites filtered by type
  List<FavoriteModel> getFavoritesByType(String type) {
    return _favorites.where((f) => f.itemType == type).toList();
  }

  /// Get job favorites
  List<FavoriteModel> get jobFavorites => getFavoritesByType('job');

  /// Get service favorites
  List<FavoriteModel> get serviceFavorites => getFavoritesByType('service');

  /// Get rental favorites
  List<FavoriteModel> get rentalFavorites => getFavoritesByType('rental');

  // --- Stream Methods ---

  /// Start listening to user's favorites
  void startListening(String userId) {
    if (_currentUserId == userId && _favoritesSubscription != null) {
      return;
    }

    stopListening();
    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _favoritesSubscription = _firebaseService
        .getUserFavoritesStream(userId)
        .listen(
          (favorites) {
            _favorites = favorites;
            _favoriteIds = favorites.map((f) => f.itemId).toSet();
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Error loading favorites: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Stop listening to favorites
  void stopListening() {
    _favoritesSubscription?.cancel();
    _favoritesSubscription = null;
    _currentUserId = null;
  }

  // --- Favorite Actions ---

  /// Check if item is favorited
  bool isFavorite(String itemId) {
    return _favoriteIds.contains(itemId);
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite({
    required String itemId,
    required String itemType,
    required String itemTitle,
  }) async {
    if (_currentUserId == null) return false;

    try {
      if (isFavorite(itemId)) {
        await _firebaseService.removeFavorite(_currentUserId!, itemId);
        _favoriteIds.remove(itemId);
        _favorites.removeWhere((f) => f.itemId == itemId);
      } else {
        await _firebaseService.addFavorite(
          userId: _currentUserId!,
          itemId: itemId,
          itemType: itemType,
          itemTitle: itemTitle,
        );
        // Local update will be handled by stream
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error toggling favorite: $e';
      notifyListeners();
      return false;
    }
  }

  /// Remove from favorites
  Future<bool> removeFavorite(String itemId) async {
    if (_currentUserId == null) return false;

    try {
      await _firebaseService.removeFavorite(_currentUserId!, itemId);
      _favoriteIds.remove(itemId);
      _favorites.removeWhere((f) => f.itemId == itemId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error removing favorite: $e';
      notifyListeners();
      return false;
    }
  }

  // --- Utility Methods ---

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
