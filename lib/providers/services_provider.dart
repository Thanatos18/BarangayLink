import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service.dart';
import '../services/firebase_service.dart';

class ServicesProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Service data
  List<ServiceModel> _allServices = [];
  List<ServiceModel> get allServices => _allServices;

  List<ServiceModel> _filteredServices = [];
  List<ServiceModel> get filteredServices => _filteredServices;

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

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Sort options
  String _sortBy = 'newest'; // 'newest', 'highest_rate', 'lowest_rate'
  String get sortBy => _sortBy;

  // Loading and error states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Stream subscription
  StreamSubscription<List<ServiceModel>>? _servicesSubscription;

  // Statuses (fixed list)
  static const List<String> serviceStatuses = ['Available', 'Unavailable'];

  ServicesProvider() {
    _initializeServices();
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

  /// Initialize services stream subscription
  void _initializeServices() {
    _setLoading(true);
    _servicesSubscription = _firebaseService
        .getServicesStream(null)
        .listen(
          (services) {
            _allServices = services;
            _applyFilters();
            _setLoading(false);
          },
          onError: (error) {
            _setError('Error loading services: $error');
            _setLoading(false);
          },
        );
  }

  /// Fetch dynamic categories from Firestore
  Future<void> _fetchCategories() async {
    try {
      final doc = await _db
          .collection('app_config')
          .doc('service_categories')
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['categories'] is List) {
          _categories = List<String>.from(data['categories']);
        }
      }

      // If no categories in Firestore, use defaults
      if (_categories.isEmpty) {
        _categories = [
          'Electrician',
          'Plumber',
          'Carpenter',
          'Cleaner',
          'Tutor',
          'Mechanic',
          'Painter',
          'Landscaper',
          'Cook',
          'Caregiver',
          'Driver',
          'Laundry',
          'Computer Repair',
          'Appliance Repair',
          'Beauty & Wellness',
          'Other',
        ];
        // Save defaults to Firestore
        await _saveDefaultCategories();
      }
      notifyListeners();
    } catch (e) {
      // Use defaults on error
      _categories = ['Electrician', 'Plumber', 'Cleaner', 'Tutor', 'Other'];
      notifyListeners();
    }
  }

  /// Save default categories to Firestore
  Future<void> _saveDefaultCategories() async {
    try {
      await _db.collection('app_config').doc('service_categories').set({
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
      await _db.collection('app_config').doc('service_categories').update({
        'categories': _categories,
        'updatedAt': Timestamp.now(),
      });
      notifyListeners();
    }
  }

  /// Apply all filters and sorting to services
  void _applyFilters() {
    _filteredServices = _allServices.where((service) {
      // Barangay filter
      if (_selectedBarangay != null &&
          _selectedBarangay != 'All Tagum City' &&
          service.barangay != _selectedBarangay) {
        return false;
      }

      // Category filter
      if (_selectedCategory != null && service.category != _selectedCategory) {
        return false;
      }

      // Availability filter
      if (_showAvailableOnly == true && !service.isAvailable) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!service.name.toLowerCase().contains(query) &&
            !service.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'highest_rate':
        _filteredServices.sort((a, b) => b.rate.compareTo(a.rate));
        break;
      case 'lowest_rate':
        _filteredServices.sort((a, b) => a.rate.compareTo(b.rate));
        break;
      case 'newest':
      default:
        _filteredServices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    _searchQuery = '';
    _sortBy = 'newest';
    _applyFilters();
  }

  // --- CRUD Operations ---

  /// Create a new service
  Future<void> createService(ServiceModel service) async {
    _setLoading(true);
    _setError(null);
    try {
      await _firebaseService.createService(service);
    } catch (e) {
      _setError('Error creating service: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing service
  Future<void> updateService(
    String serviceId,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      data['updatedAt'] = Timestamp.now();
      await _firebaseService.updateService(serviceId, data);
    } catch (e) {
      _setError('Error updating service: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a service
  Future<void> deleteService(String serviceId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _firebaseService.deleteService(serviceId);
    } catch (e) {
      _setError('Error deleting service: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Book a service
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
    _setLoading(true);
    _setError(null);
    try {
      await _firebaseService.bookService(
        serviceId: serviceId,
        serviceName: serviceName,
        providerId: providerId,
        providerName: providerName,
        clientId: clientId,
        clientName: clientName,
        barangay: barangay,
        rate: rate,
      );
    } catch (e) {
      _setError('Error booking service: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get a single service by ID (local)
  ServiceModel? getServiceById(String serviceId) {
    try {
      return _allServices.firstWhere((service) => service.id == serviceId);
    } catch (e) {
      return null;
    }
  }

  /// Fetch a single service by ID (local or remote)
  Future<ServiceModel?> fetchServiceById(String serviceId) async {
    // Try local first
    final localService = getServiceById(serviceId);
    if (localService != null) return localService;

    // Fetch from Firebase
    try {
      return await _firebaseService.getService(serviceId);
    } catch (e) {
      debugPrint('Error fetching service: $e');
      return null;
    }
  }

  /// Get services by a specific user
  List<ServiceModel> getServicesByUser(String userId) {
    return _allServices
        .where((service) => service.providerId == userId)
        .toList();
  }

  @override
  void dispose() {
    _servicesSubscription?.cancel();
    super.dispose();
  }
}
