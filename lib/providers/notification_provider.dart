import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/firebase_service.dart';

/// Provider for managing notifications state.
class NotificationProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // --- State ---
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscription
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;
  String? _currentUserId;

  // --- Getters ---

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnread => _unreadCount > 0;

  /// Get notifications grouped by date
  Map<String, List<NotificationModel>> get groupedNotifications {
    final Map<String, List<NotificationModel>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var notification in _notifications) {
      final notifDate = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      String key;
      if (notifDate == today) {
        key = 'Today';
      } else if (notifDate == yesterday) {
        key = 'Yesterday';
      } else {
        key = 'Earlier';
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(notification);
    }

    return grouped;
  }

  // --- Stream Methods ---

  /// Start listening to user's notifications
  void startListening(String userId) {
    if (_currentUserId == userId && _notificationSubscription != null) {
      return;
    }

    stopListening();
    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _notificationSubscription = _firebaseService
        .getUserNotificationsStream(userId)
        .listen(
          (notifications) {
            _notifications = notifications;
            _unreadCount = notifications.where((n) => !n.isRead).length;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Error loading notifications: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Stop listening to notifications
  void stopListening() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _currentUserId = null;
  }

  // --- Notification Actions ---

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firebaseService.markNotificationAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error marking notification as read: $e';
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      await _firebaseService.markAllNotificationsAsRead(_currentUserId!);

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error marking all as read: $e';
      notifyListeners();
    }
  }

  /// Create a notification
  Future<void> createNotification({
    required String type,
    required String title,
    required String message,
    required String userId,
    String? relatedId,
    String? relatedType,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        type: type,
        title: title,
        message: message,
        relatedId: relatedId,
        relatedType: relatedType,
        userId: userId,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await _firebaseService.createNotification(notification);
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  // --- Utility Methods ---

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh unread count
  Future<void> refreshUnreadCount() async {
    if (_currentUserId == null) return;

    try {
      _unreadCount = await _firebaseService.getUnreadNotificationCount(
        _currentUserId!,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing unread count: $e');
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
