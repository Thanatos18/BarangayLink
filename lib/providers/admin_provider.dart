import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/report.dart';
import '../services/firebase_service.dart';

/// Provider for admin dashboard and moderation functionality.
class AdminProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // --- State ---
  List<UserModel> _allUsers = [];
  List<ReportModel> _reports = [];
  Map<String, int> _adminStats = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _reportFilter = 'all'; // 'all', 'pending', 'resolved', 'dismissed'

  // Stream subscription
  StreamSubscription<List<ReportModel>>? _reportsSubscription;

  // --- Getters ---

  List<UserModel> get allUsers => _filteredUsers;
  List<ReportModel> get reports => _filteredReports;
  Map<String, int> get adminStats => _adminStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get reportFilter => _reportFilter;

  /// Filter users based on search query
  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _allUsers;
    }
    final query = _searchQuery.toLowerCase();
    return _allUsers.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.barangay.toLowerCase().contains(query);
    }).toList();
  }

  /// Filter reports based on filter selection
  List<ReportModel> get _filteredReports {
    if (_reportFilter == 'all') {
      return _reports;
    }
    return _reports.where((r) => r.status == _reportFilter).toList();
  }

  /// Get count of pending reports
  int get pendingReportsCount => _reports.where((r) => r.isPending).length;

  // --- Initialization ---

  /// Initialize admin data
  Future<void> initialize() async {
    await Future.wait([fetchUsers(), fetchAdminStats()]);
    startListeningToReports();
  }

  // --- User Management ---

  /// Fetch all users
  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allUsers = await _firebaseService.getAllUsers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error fetching users: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search users
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Ban a user
  Future<bool> banUser(String uid) async {
    try {
      await _firebaseService.updateUserBanStatus(uid, true);
      // Update local state
      final index = _allUsers.indexWhere((u) => u.uid == uid);
      if (index != -1) {
        _allUsers[index] = _allUsers[index].copyWith(isBanned: true);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Error banning user: $e';
      notifyListeners();
      return false;
    }
  }

  /// Unban a user
  Future<bool> unbanUser(String uid) async {
    try {
      await _firebaseService.updateUserBanStatus(uid, false);
      // Update local state
      final index = _allUsers.indexWhere((u) => u.uid == uid);
      if (index != -1) {
        _allUsers[index] = _allUsers[index].copyWith(isBanned: false);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Error unbanning user: $e';
      notifyListeners();
      return false;
    }
  }

  // --- Report Management ---

  /// Start listening to reports
  void startListeningToReports() {
    _reportsSubscription?.cancel();
    _reportsSubscription = _firebaseService.getReportsStream().listen(
      (reports) {
        _reports = reports;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error loading reports: $error';
        notifyListeners();
      },
    );
  }

  /// Stop listening to reports
  void stopListeningToReports() {
    _reportsSubscription?.cancel();
    _reportsSubscription = null;
  }

  /// Set report filter
  void setReportFilter(String filter) {
    _reportFilter = filter;
    notifyListeners();
  }

  /// Submit a new report
  Future<bool> submitReport({
    required String reportedItemId,
    required String reportedItemType,
    required String reportedItemTitle,
    required String reportedBy,
    String? reportedByName,
    required String reason,
    String? additionalDetails,
  }) async {
    try {
      final report = ReportModel(
        id: '',
        reportedItemId: reportedItemId,
        reportedItemType: reportedItemType,
        reportedItemTitle: reportedItemTitle,
        reportedBy: reportedBy,
        reportedByName: reportedByName,
        reason: reason,
        additionalDetails: additionalDetails,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      await _firebaseService.submitReport(report);
      return true;
    } catch (e) {
      _errorMessage = 'Error submitting report: $e';
      notifyListeners();
      return false;
    }
  }

  /// Resolve a report (take action)
  Future<bool> resolveReport(
    String reportId,
    String resolution,
    String resolvedBy,
  ) async {
    try {
      await _firebaseService.resolveReport(reportId, resolution, resolvedBy);
      return true;
    } catch (e) {
      _errorMessage = 'Error resolving report: $e';
      notifyListeners();
      return false;
    }
  }

  /// Dismiss a report (no action needed)
  Future<bool> dismissReport(String reportId, String resolvedBy) async {
    try {
      await _firebaseService.dismissReport(reportId, resolvedBy);
      return true;
    } catch (e) {
      _errorMessage = 'Error dismissing report: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete reported content
  Future<bool> deleteReportedContent(
    ReportModel report,
    String adminUid,
  ) async {
    try {
      // Determine collection based on report type
      String collection;
      switch (report.reportedItemType) {
        case 'job':
          collection = 'barangay_jobs';
          break;
        case 'service':
          collection = 'barangay_services';
          break;
        case 'rental':
          collection = 'barangay_rentals';
          break;
        default:
          throw Exception('Unknown item type');
      }

      // Delete the item
      await _firebaseService.deleteItem(collection, report.reportedItemId);

      // Resolve the report
      await resolveReport(report.id, 'Content deleted', adminUid);

      return true;
    } catch (e) {
      _errorMessage = 'Error deleting content: $e';
      notifyListeners();
      return false;
    }
  }

  // --- Admin Stats ---

  /// Fetch admin dashboard statistics
  Future<void> fetchAdminStats() async {
    try {
      _adminStats = await _firebaseService.getAdminStats();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error fetching stats: $e';
      notifyListeners();
    }
  }

  // --- Utility Methods ---

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh all admin data
  Future<void> refresh() async {
    await initialize();
  }

  @override
  void dispose() {
    stopListeningToReports();
    super.dispose();
  }
}
