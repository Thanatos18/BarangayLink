import 'dart:async';
import 'package:flutter/material.dart';
import '../models/favorite.dart';
import '../services/firebase_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<FavoriteModel> _favorites = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FavoriteModel> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Convenience getters for filtered lists
  List<FavoriteModel> get jobFavorites =>
      _favorites.where((f) => f.isJob).toList();
  List<FavoriteModel> get serviceFavorites =>
      _favorites.where((f) => f.isService).toList();
  List<FavoriteModel> get rentalFavorites =>
      _favorites.where((f) => f.isRental).toList();

  // Stream subscription
  StreamSubscription<List<FavoriteModel>>? _favoritesSubscription;
  String? _currentUserId;

  void startListening(String userId) {
    if (_currentUserId == userId && _favoritesSubscription != null) {
      return;
    }

    stopListening();
    _currentUserId = userId;
    _isLoading = true;
    // Notify listeners in microtask to avoid build conflicts
    Future.microtask(() => notifyListeners());

    _favoritesSubscription =
        _firebaseService.getUserFavoritesStream(userId).listen(
      (favoritesData) {
        _favorites = favoritesData;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _favoritesSubscription?.cancel();
    _favoritesSubscription = null;
    _currentUserId = null;
  }

  Future<void> toggleFavorite(FavoriteModel favorite) async {
    // 1. Check if it's already a favorite
    final isFav = isFavorite(favorite.itemId);

    // 2. Optimistic Update (Update local state immediately)
    if (isFav) {
      _favorites.removeWhere((f) => f.itemId == favorite.itemId);
    } else {
      _favorites.add(favorite);
    }
    notifyListeners(); // Update UI instantly

    // 3. Perform actual server operation
    try {
      await _firebaseService.toggleFavorite(favorite);
      // The stream will eventually update and sync state, which is fine.
    } catch (e) {
      // 4. Revert if failed
      if (isFav) {
        _favorites.add(favorite);
      } else {
        _favorites.removeWhere((f) => f.itemId == favorite.itemId);
      }
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  bool isFavorite(String itemId) {
    return _favorites.any((f) => f.itemId == itemId);
  }
}
