import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job.dart';
import '../services/firebase_service.dart';

class JobsProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Job data
  List<JobModel> _allJobs = [];
  List<JobModel> get allJobs => _allJobs;

  List<JobModel> _filteredJobs = [];
  List<JobModel> get filteredJobs => _filteredJobs;

  // Dynamic categories from Firestore
  List<String> _categories = [];
  List<String> get categories => _categories;

  // Filter states
  String? _selectedBarangay;
  String? get selectedBarangay => _selectedBarangay;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  String? _selectedStatus;
  String? get selectedStatus => _selectedStatus;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Sort options
  String _sortBy = 'newest'; // 'newest', 'highest_wage', 'lowest_wage'
  String get sortBy => _sortBy;

  // Loading and error states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Stream subscription
  StreamSubscription<List<JobModel>>? _jobsSubscription;

  // Statuses (fixed list)
  static const List<String> jobStatuses = ['Open', 'In Progress', 'Completed'];

  JobsProvider() {
    _initializeJobs();
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

  /// Initialize jobs stream subscription
  void _initializeJobs() {
    _setLoading(true);
    _jobsSubscription = _firebaseService.getJobsStream(null).listen(
      (jobs) {
        _allJobs = jobs;
        _applyFilters();
        _setLoading(false);
      },
      onError: (error) {
        _setError('Error loading jobs: $error');
        _setLoading(false);
      },
    );
  }

  /// Fetch dynamic categories from Firestore
  Future<void> _fetchCategories() async {
    try {
      final doc =
          await _db.collection('app_config').doc('job_categories').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['categories'] is List) {
          _categories = List<String>.from(data['categories']);
        }
      }

      // If no categories in Firestore, use defaults
      if (_categories.isEmpty) {
        _categories = [
          'Plumbing',
          'Electrical',
          'Tutoring',
          'Cleaning',
          'Repair',
          'Construction',
          'Delivery',
          'Agriculture',
          'Carpentry',
          'Painting',
          'Landscaping',
          'Cooking',
          'Caregiving',
          'Other',
        ];
        // Optionally save defaults to Firestore
        await _saveDefaultCategories();
      }
      notifyListeners();
    } catch (e) {
      // Use defaults on error
      _categories = [
        'Plumbing',
        'Electrical',
        'Tutoring',
        'Cleaning',
        'Repair',
        'Other'
      ];
      notifyListeners();
    }
  }

  /// Save default categories to Firestore for future dynamic updates
  Future<void> _saveDefaultCategories() async {
    try {
      await _db.collection('app_config').doc('job_categories').set({
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
      await _db.collection('app_config').doc('job_categories').update({
        'categories': _categories,
        'updatedAt': Timestamp.now(),
      });
      notifyListeners();
    }
  }

  /// Apply all filters and sorting to jobs
  void _applyFilters() {
    _filteredJobs = _allJobs.where((job) {
      // Barangay filter
      if (_selectedBarangay != null &&
          _selectedBarangay != 'All Tagum City' &&
          job.barangay != _selectedBarangay) {
        return false;
      }

      // Category filter
      if (_selectedCategory != null && job.category != _selectedCategory) {
        return false;
      }

      // Status filter
      if (_selectedStatus != null && job.status != _selectedStatus) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!job.title.toLowerCase().contains(query) &&
            !job.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'highest_wage':
        _filteredJobs.sort((a, b) => b.wage.compareTo(a.wage));
        break;
      case 'lowest_wage':
        _filteredJobs.sort((a, b) => a.wage.compareTo(b.wage));
        break;
      case 'newest':
      default:
        _filteredJobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  void setStatusFilter(String? status) {
    _selectedStatus = status;
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
    _selectedStatus = null;
    _searchQuery = '';
    _sortBy = 'newest';
    _applyFilters();
  }

  // --- CRUD Operations ---

  /// Create a new job
  Future<void> createJob(JobModel job) async {
    _setLoading(true);
    _setError(null);
    try {
      await _firebaseService.createJob(job);
      // Stream will automatically update _allJobs
    } catch (e) {
      _setError('Error creating job: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing job
  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      data['updatedAt'] = Timestamp.now();
      await _firebaseService.updateJob(jobId, data);
    } catch (e) {
      _setError('Error updating job: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a job
  Future<void> deleteJob(String jobId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _firebaseService.deleteJob(jobId);
    } catch (e) {
      _setError('Error deleting job: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Apply to a job
  Future<void> applyToJob({
    required String jobId,
    required String jobTitle,
    required String posterId,
    required String posterName,
    required String applicantId,
    required String applicantName,
    required String barangay,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _firebaseService.applyToJob(
        jobId,
        jobTitle,
        posterId,
        posterName,
        applicantId,
        applicantName,
        barangay,
      );
    } catch (e) {
      _setError('Error applying to job: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user has already applied to a job
  bool hasUserApplied(JobModel job, String userId) {
    return job.applicants.any((applicant) => applicant.userId == userId);
  }

  /// Get a single job by ID
  JobModel? getJobById(String jobId) {
    try {
      return _allJobs.firstWhere((job) => job.id == jobId);
    } catch (e) {
      return null;
    }
  }

  /// Get jobs posted by a specific user
  List<JobModel> getJobsByUser(String userId) {
    return _allJobs.where((job) => job.postedBy == userId).toList();
  }

  @override
  void dispose() {
    _jobsSubscription?.cancel();
    super.dispose();
  }
}
