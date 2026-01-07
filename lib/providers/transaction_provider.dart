import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/notification.dart';
import '../services/firebase_service.dart';

/// Provider for managing transaction state with real-time updates.
/// Handles filtering by type and status, and provides methods for status updates.
class TransactionProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // --- State ---
  List<TransactionModel> _allTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedTypeFilter; // null = All
  String? _selectedStatusFilter; // null = All

  // Stream subscription
  StreamSubscription<List<TransactionModel>>? _transactionSubscription;
  String? _currentUserId;

  // --- Getters ---

  List<TransactionModel> get allTransactions => _allTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedTypeFilter => _selectedTypeFilter;
  String? get selectedStatusFilter => _selectedStatusFilter;

  /// Returns filtered transactions based on current filter settings
  List<TransactionModel> get filteredTransactions {
    List<TransactionModel> result = List.from(_allTransactions);

    // Apply type filter
    if (_selectedTypeFilter != null && _selectedTypeFilter!.isNotEmpty) {
      result = result.where((t) => t.type == _selectedTypeFilter).toList();
    }

    // Apply status filter
    if (_selectedStatusFilter != null && _selectedStatusFilter!.isNotEmpty) {
      result = result.where((t) => t.status == _selectedStatusFilter).toList();
    }

    return result;
  }

  /// Transaction type options for filtering
  static const List<Map<String, String>> typeOptions = [
    {'value': '', 'label': 'All Types'},
    {'value': 'job_application', 'label': 'Job Applications'},
    {'value': 'service_booking', 'label': 'Service Bookings'},
    {'value': 'rental_request', 'label': 'Rental Requests'},
  ];

  /// Transaction status options for filtering
  static const List<Map<String, String>> statusOptions = [
    {'value': '', 'label': 'All Status'},
    {'value': 'Pending', 'label': 'Pending'},
    {'value': 'Accepted', 'label': 'Accepted'},
    {'value': 'In Progress', 'label': 'In Progress'},
    {'value': 'Completed', 'label': 'Completed'},
    {'value': 'Cancelled', 'label': 'Cancelled'},
  ];

  // --- List Management Methods ---

  /// Start listening to user's transactions (both initiated and target)
  void startListening(String userId) {
    // Don't restart if already listening to same user
    if (_currentUserId == userId && _transactionSubscription != null) {
      return;
    }

    // Stop any existing subscription
    stopListening();

    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _transactionSubscription =
        _firebaseService.getUserTransactionsStream(userId).listen(
      (transactions) {
        _allTransactions = transactions;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error loading transactions: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Stop listening to transaction updates
  void stopListening() {
    _transactionSubscription?.cancel();
    _transactionSubscription = null;
    _currentUserId = null;
  }

  // --- Filter Methods ---

  void setTypeFilter(String? type) {
    _selectedTypeFilter = (type == null || type.isEmpty) ? null : type;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _selectedStatusFilter = (status == null || status.isEmpty) ? null : status;
    notifyListeners();
  }

  void clearFilters() {
    _selectedTypeFilter = null;
    _selectedStatusFilter = null;
    notifyListeners();
  }

  // --- Transaction Actions ---

  /// Update transaction status (Accept, Decline, etc.)
  Future<bool> updateTransactionStatus(
      String transactionId, String newStatus) async {
    try {
      await _firebaseService.updateTransactionStatus(transactionId, newStatus);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update status: $e';
      notifyListeners();
      return false;
    }
  }

  /// Accept a transaction (for target user)
  Future<bool> acceptTransaction(String transactionId) async {
    final success = await updateTransactionStatus(transactionId, 'Accepted');
    if (success) {
      final transaction = await _firebaseService.getTransaction(transactionId);
      if (transaction != null) {
        await _sendTransactionNotification(
          transactionId,
          NotificationType.transactionUpdate,
          'Request Accepted',
          'Your ${transaction.typeLabel.toLowerCase()} regarding ${transaction.relatedName} has been accepted!',
          transaction.initiatedBy,
        );
      }
    }
    return success;
  }

  /// Decline a transaction (for target user)
  Future<bool> declineTransaction(String transactionId) async {
    final success = await updateTransactionStatus(transactionId, 'Cancelled');
    if (success) {
      final transaction = await _firebaseService.getTransaction(transactionId);
      if (transaction != null) {
        await _sendTransactionNotification(
          transactionId,
          NotificationType.transactionUpdate,
          'Request Declined',
          'Your request for ${transaction.relatedName} was declined.',
          transaction.initiatedBy,
        );
      }
    }
    return success;
  }

  /// Cancel a transaction (for initiator or target)
  Future<bool> cancelTransaction(String transactionId) async {
    return await updateTransactionStatus(transactionId, 'Cancelled');
  }

  /// Confirm payment and move to In Progress
  Future<bool> confirmPayment(String transactionId) async {
    try {
      await _firebaseService.confirmPayment(transactionId);
      // Notify provider that payment is received
      final transaction = await _firebaseService.getTransaction(transactionId);
      if (transaction != null) {
        await _sendTransactionNotification(
          transactionId,
          NotificationType.paymentReceived,
          'Payment Received',
          'Payment received for ${transaction.relatedName}. Transaction is now in progress.',
          transaction.targetUser,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to confirm payment: $e';
      notifyListeners();
      return false;
    }
  }

  /// Complete a transaction
  Future<bool> completeTransaction(String transactionId) async {
    try {
      await _firebaseService.completeTransaction(transactionId);

      // Notify target (provider/owner)
      final transaction = await _firebaseService.getTransaction(transactionId);
      if (transaction != null) {
        await _sendTransactionNotification(
          transactionId,
          NotificationType.transactionUpdate,
          'Transaction Completed',
          'The transaction for ${transaction.relatedName} has been marked as completed.',
          transaction.targetUser,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete transaction: $e';
      notifyListeners();
      return false;
    }
  }

  // --- Utility Methods ---

  /// Get a single transaction by ID
  Future<TransactionModel?> getTransactionById(String transactionId) async {
    try {
      return await _firebaseService.getTransaction(transactionId);
    } catch (e) {
      _errorMessage = 'Failed to get transaction: $e';
      notifyListeners();
      return null;
    }
  }

  /// Get the name of the other party in a transaction
  Future<String> getOtherPartyName(
      TransactionModel transaction, String currentUserId) async {
    if (transaction.initiatedBy == currentUserId) {
      // Current user is initiator, return target's name
      return transaction.targetUserName ??
          await _firebaseService.getUserName(transaction.targetUser);
    } else {
      // Current user is target, return initiator's name
      return transaction.initiatedByName ??
          await _firebaseService.getUserName(transaction.initiatedBy);
    }
  }

  /// Check if current user is the initiator of this transaction
  bool isInitiator(TransactionModel transaction, String currentUserId) {
    return transaction.initiatedBy == currentUserId;
  }

  /// Check if current user is the target of this transaction
  bool isTarget(TransactionModel transaction, String currentUserId) {
    return transaction.targetUser == currentUserId;
  }

  /// Send a notification related to a transaction
  Future<void> _sendTransactionNotification(
    String transactionId,
    String type,
    String title,
    String message,
    String targetUserId,
  ) async {
    try {
      final notification = NotificationModel(
        id: '',
        type: type,
        title: title,
        message: message,
        relatedId: transactionId,
        relatedType: 'transaction',
        userId: targetUserId,
        createdAt: DateTime.now(),
      );
      await _firebaseService.createNotification(notification);
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
