import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/rentals_provider.dart';
import '../details/job_detail_screen.dart';
import '../details/service_detail_screen.dart';
import '../details/rental_detail_screen.dart';
import '../../providers/transaction_provider.dart';
import '../transaction/transaction_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(
        context,
        listen: false,
      ).currentUser;
      if (user != null) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).startListening(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        showBackButton: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'read') {
                await notificationProvider.markAllAsRead();
              } else if (value == 'clear') {
                _showClearAllDialog(context, notificationProvider);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'read',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Mark all read'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildNotificationList(notificationProvider),
    );
  }

  Widget _buildNotificationList(NotificationProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(provider.errorMessage!),
          ],
        ),
      );
    }

    if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll receive updates here',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final grouped = provider.groupedNotifications;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final key = grouped.keys.elementAt(index);
        final notifications = grouped[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: EdgeInsets.only(bottom: 8, top: index > 0 ? 16 : 0),
              child: Text(
                key,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            // Notification Cards
            ...notifications.map((n) => _buildNotificationCard(n, provider)),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard(
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await provider.deleteNotification(notification.id);
      },
      onDismissed: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification removed'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: notification.isRead ? 0 : 2,
        color: notification.isRead ? Colors.grey[50] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification.isRead
                ? Colors.grey.shade200
                : Colors.grey.shade300,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(notification, provider),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon based on type
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        _getTypeColor(notification.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(notification.type),
                    color: _getTypeColor(notification.type),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                          fontSize: 16,
                          color: notification.isRead
                              ? Colors.grey[800]
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Unread Indicator
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: kPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog(
    BuildContext context,
    NotificationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
          'This action cannot be undone. All your notifications will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.clearAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared')),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificationTap(
    NotificationModel notification,
    NotificationProvider provider,
  ) async {
    // Mark as read
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    if (notification.relatedId == null || notification.relatedType == null) {
      return;
    }

    final String relatedId = notification.relatedId!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      Widget? destination;

      switch (notification.relatedType) {
        case 'job':
          final job = await Provider.of<JobsProvider>(
            context,
            listen: false,
          ).fetchJobById(relatedId);
          if (job != null) {
            destination = JobDetailScreen(job: job);
          }
          break;

        case 'service':
          final service = await Provider.of<ServicesProvider>(
            context,
            listen: false,
          ).fetchServiceById(relatedId);
          if (service != null) {
            destination = ServiceDetailScreen(service: service);
          }
          break;

        case 'rental':
          final rental = await Provider.of<RentalsProvider>(
            context,
            listen: false,
          ).fetchRentalById(relatedId);
          if (rental != null) {
            destination = RentalDetailScreen(rental: rental);
          }
          break;

        case 'transaction':
          final transaction = await Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).getTransactionById(relatedId);
          if (transaction != null) {
            destination = TransactionDetailScreen(transaction: transaction);
          }
          break;
      }

      if (destination != null) {
        navigator.pop(); // Close loading dialog
        navigator.push(
          MaterialPageRoute(builder: (_) => destination!),
        );
      } else {
        navigator.pop(); // Close loading dialog
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Item not found or no longer available'),
          ),
        );
      }
    } catch (e) {
      navigator.pop(); // Close loading dialog
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case NotificationType.transactionUpdate:
        return Icons.receipt_long;
      case NotificationType.newApplication:
        return Icons.person_add;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.feedbackReceived:
        return Icons.star;
      case NotificationType.reportResolved:
        return Icons.flag;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case NotificationType.transactionUpdate:
        return Colors.blue;
      case NotificationType.newApplication:
        return Colors.green;
      case NotificationType.paymentReceived:
        return Colors.orange;
      case NotificationType.feedbackReceived:
        return kAccentColor;
      case NotificationType.reportResolved:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
