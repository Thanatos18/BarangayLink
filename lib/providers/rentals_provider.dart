import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental.dart';
import '../services/firebase_service.dart';

class RentalsProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Rental data
  List<RentalModel> _allRentals = [];
  List<RentalModel> get allRentals => _allRentals;

  List<RentalModel> _filteredRentals = [];
  List<RentalModel> get filteredRentals => _filteredRentals;

  // Dynamic categories from Firestore
  List<String> _categories = [];
  List<String> get categories => _categories;

  // Filter states
  String? _selectedBarangay;
  String? get selectedBarangay => _selectedBarangay;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  bool? _showAvailableOnly;
  bool? get showAvailableOnly => _showAvailableOnly;

  String? _selectedCondition;
  String? get selectedCondition => _selectedCondition;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Sort options
  String _sortBy = 'newest'; // 'newest', 'highest_price', 'lowest_price'
  String get sortBy => _sortBy;

  // Loading and error states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Stream subscription
  StreamSubscription<List<RentalModel>>? _rentalsSubscription;

  // Condition options (fixed list)
  static const List<String> conditionOptions = ['Good', 'Fair', 'Needs Repair'];

  RentalsProvider() {
    _initializeRentals();
    _fetchCategories();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Initialize rentals stream subscription
  void _initializeRentals() {
    _setLoading(true);
    _rentalsSubscription = _firebaseService.getRentalsStream(null).listen(
      (rentals) {
        _allRentals = rentals;
        _applyFilters();
        _setLoading(false);
      },
      onError: (error) {
        _setError('Error loading rentals: $error');
        _setLoading(false);
      },
    );
  }

  /// Fetch dynamic categories from Firestore
  Future<void> _fetchCategories() async {
    try {
      final doc =
          await _db.collection('app_config').doc('rental_categories').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['categories'] is List) {
          _categories = List<String>.from(data['categories']);
        }
      }

      // If no categories in Firestore, use defaults
      if (_categories.isEmpty) {
        _categories = [
          'Tools & Equipment',
          'Electronics',
          'Furniture',
          'Vehicles',
          'Sports Equipment',
          'Party Supplies',
          'Kitchen Appliances',
          'Garden Equipment',
          'Musical Instruments',
          'Cameras & Lighting',
          'Clothing & Costumes',
          'Other',
        ];
        // Save defaults to Firestore
        await _saveDefaultCategories();
      }
      notifyListeners();
    } catch (e) {
      // Use defaults on error
      _categories = ['Tools & Equipment', 'Electronics', 'Furniture', 'Other'];
      notifyListeners();
    }
  }

  /// Save default categories to Firestore
  Future<void> _saveDefaultCategories() async {
    try {
      await _db.collection('app_config').doc('rental_categories').set({
        'categories': _categories,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      // Silently fail - defaults are already in memory
    }
  }

  /// Add a new category dynamically
  Future<void> addCategory(String category) async {
    if (!_categories.contains(category)) {
      _categories.add(category);
      _categories.sort();
      await _db.collection('app_config').doc('rental_categories').update({
        'categories': _categories,
        'updatedAt': Timestamp.now(),
      });
      notifyListeners();
    }
  }

  /// Apply all filters and sorting to rentals
  void _applyFilters() {
    _filteredRentals = _allRentals.where((rental) {
      // Barangay filter
      if (_selectedBarangay != null &&
          _selectedBarangay != 'All Tagum City' &&
          rental.barangay != _selectedBarangay) {
        return false;
      }

      // Category filter
      if (_selectedCategory != null && rental.category != _selectedCategory) {
        return false;
      }

      // Availability filter
      if (_showAvailableOnly == true && !rental.isAvailable) {
        return false;
      }

      // Condition filter
      if (_selectedCondition != null &&
          rental.condition != _selectedCondition) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!rental.itemName.toLowerCase().contains(query) &&
            !rental.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'highest_price':
        _filteredRentals.sort((a, b) => b.rentPrice.compareTo(a.rentPrice));
        break;
      case 'lowest_price':
        _filteredRentals.sort((a, b) => a.rentPrice.compareTo(b.rentPrice));
        break;
      case 'newest':
      default:
        _filteredRentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    notifyListeners();
  }

  // --- Filter Setters ---

  void setBarangayFilter(String? barangay) {
    _selectedBarangay = barangay;
    _applyFilters();
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void setAvailabilityFilter(bool? availableOnly) {
    _showAvailableOnly = availableOnly;
    _applyFilters();
  }

  void setConditionFilter(String? condition) {
    _selectedCondition = condition;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setSortBy(String sortOption) {
    _sortBy = sortOption;
    _applyFilters();
  }

  void clearFilters() {
    _selectedBarangay = null;
    _selectedCategory = null;
    _showAvailableOnly = null;
    _selectedCondition = null;
    _searchQuery = '';
    _sortBy = 'newest';
    _applyFilters();
  }

  // --- CRUD Operations ---

  /// Create a new rental
  Future<void> createRental(RentalModel rental) async {
    _setLoading(true);
    _setError(null);
    try {
      await _firebaseService.createRental(rental);
    } catch (e) {
      _setError('Error creating rental: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing rental
  Future<void> updateRental(String rentalId, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      data['updatedAt'] = Timestamp.now();
      await _firebaseService.updateRental(rentalId, data);
    } catch (e) {
      _setError('Error updating rental: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a rental
  Future<void> deleteRental(String rentalId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _firebaseService.deleteRental(rentalId);
    } catch (e) {
      _setError('Error deleting rental: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Request a rental
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
    _setLoading(true);
    _setError(null);
    try {
      await _firebaseService.requestRental(
        rentalId: rentalId,
        itemName: itemName,
        ownerId: ownerId,
        ownerName: ownerName,
        renterId: renterId,
        renterName: renterName,
        barangay: barangay,
        rentPrice: rentPrice,
      );
    } catch (e) {
      _setError('Error requesting rental: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get a single rental by ID
  RentalModel? getRentalById(String rentalId) {
    try {
      return _allRentals.firstWhere((rental) => rental.id == rentalId);
    } catch (e) {
      return null;
    }
  }

  /// Get rentals by a specific user
  List<RentalModel> getRentalsByUser(String userId) {
    return _allRentals.where((rental) => rental.ownerId == userId).toList();
  }

  @override
  void dispose() {
    _rentalsSubscription?.cancel();
    super.dispose();
  }
}
