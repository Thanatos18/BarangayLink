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

  void startListening(String userId) {
    _isLoading = true;
    notifyListeners();

    _firebaseService
        .getUserFavoritesStream(userId)
        .listen(
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

  Future<void> toggleFavorite(FavoriteModel favorite) async {
    try {
      // Optimistic update could be done here, but since stream updates automatically,
      // we just call the service.
      await _firebaseService.toggleFavorite(favorite);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  bool isFavorite(String itemId) {
    return _favorites.any((f) => f.itemId == itemId);
  }
}
