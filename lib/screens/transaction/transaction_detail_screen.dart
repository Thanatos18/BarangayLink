import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'payment_confirmation_screen.dart';
import 'submit_feedback_screen.dart';
import '../../widgets/modern_dialog.dart';

import '../../services/firebase_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late String? _initiatedByName;
  late String? _targetUserName;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _initiatedByName = widget.transaction.initiatedByName;
    _targetUserName = widget.transaction.targetUserName;
    _fetchMissingNames();
  }

  Future<void> _fetchMissingNames() async {
    bool needsUpdate = false;

    if (_initiatedByName == null) {
      try {
        final user = await _firebaseService
            .getUserDocument(widget.transaction.initiatedBy);
        if (user != null) {
          _initiatedByName = user.name;
          needsUpdate = true;
        }
      } catch (e) {
        // Ignore error, will stay as "Loading..." or could set to "Unknown"
        debugPrint('Error fetching initiator name: $e');
      }
    }

    if (_targetUserName == null) {
      try {
        final user = await _firebaseService
            .getUserDocument(widget.transaction.targetUser);
        if (user != null) {
          _targetUserName = user.name;
          needsUpdate = true;
        }
      } catch (e) {
        debugPrint('Error fetching target user name: $e');
      }
    }

    if (needsUpdate && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Transaction Details'),
        body: Center(child: Text('Please log in')),
      );
    }

    final isInitiator = widget.transaction.initiatedBy == currentUser.uid;
    final isTarget = widget.transaction.targetUser == currentUser.uid;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Transaction Details',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Header
            _buildTypeHeader(),
            const SizedBox(height: 24),

            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Details Card
            _buildDetailsCard(isInitiator),
            const SizedBox(height: 16),

            // Amount Card (if has amount)
            if (widget.transaction.transactionAmount > 0) ...[
              _buildAmountCard(),
              const SizedBox(height: 16),
            ],

            // Timeline Card
            _buildTimelineCard(),
            // Extra spacing for scroll visibility if needed
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(
        context,
        transactionProvider,
        isInitiator,
        isTarget,
      ),
    );
  }

  Widget _buildTypeHeader() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(_getTypeIcon(), color: _getTypeColor(), size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.transaction.typeLabel,
                style: TextStyle(
                  color: _getTypeColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.transaction.relatedName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(_getStatusIcon(), color: _getStatusColor(), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.transaction.status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
            ),
            // Payment Status Badge
            if (widget.transaction.transactionAmount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.transaction.isPaid
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.transaction.isPaid
                          ? Icons.check_circle
                          : Icons.pending,
                      size: 16,
                      color: widget.transaction.isPaid
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.transaction.paymentStatus,
                      style: TextStyle(
                        color: widget.transaction.isPaid
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(bool isInitiator) {
    final otherPartyName = isInitiator
        ? (_targetUserName ?? 'Loading...')
        : (_initiatedByName ?? 'Loading...');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.person,
              label: isInitiator ? 'Posted by' : 'Requested by',
              value: otherPartyName,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.location_on,
              label: 'Barangay',
              value: widget.transaction.barangay,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              icon: Icons.category,
              label: 'Type',
              value: widget.transaction.typeLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard() {
    return Card(
      elevation: 2,
      color: kPrimaryColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaction Amount',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              '$kCurrencySymbol${widget.transaction.transactionAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: kPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timeline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              icon: Icons.add_circle,
              label: 'Created',
              date: widget.transaction.createdAt,
              isFirst: true,
            ),
            _buildTimelineItem(
              icon: Icons.update,
              label: 'Last Updated',
              date: widget.transaction.updatedAt,
            ),
            if (widget.transaction.completedAt != null)
              _buildTimelineItem(
                icon: Icons.check_circle,
                label: 'Completed',
                date: widget.transaction.completedAt!,
                isLast: true,
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String label,
    required DateTime date,
    bool isFirst = false,
    bool isLast = false,
    Color? color,
  }) {
    return Row(
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(width: 2, height: 12, color: Colors.grey[300]),
            Icon(icon, size: 20, color: color ?? Colors.grey[600]),
            if (!isLast)
              Container(width: 2, height: 12, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color ?? Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDateTime(date),
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomActions(
    BuildContext context,
    TransactionProvider provider,
    bool isInitiator,
    bool isTarget,
  ) {
    Widget? actionContent;

    // Target user actions for Pending transactions (Accept/Decline)
    if (isTarget && widget.transaction.isPending) {
      actionContent = Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleAccept(context, provider),
              icon: const Icon(Icons.check),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleDecline(context, provider),
              icon: const Icon(Icons.close),
              label: const Text('Decline'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }
    // Pay Now button for Accepted transactions
    else if (widget.transaction.isAccepted && !widget.transaction.isPaid) {
      actionContent = SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _navigateToPayment(context),
          icon: const Icon(Icons.payment),
          label: const Text('Pay Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kAccentColor,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    // Mark as Completed button for In Progress transactions (initiator only)
    else if (isInitiator && widget.transaction.isInProgress) {
      actionContent = SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _handleComplete(context, provider),
          icon: const Icon(Icons.check_circle),
          label: const Text('Mark as Completed'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    // Leave Feedback button for Completed transactions
    else if (widget.transaction.isCompleted) {
      actionContent = SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _navigateToFeedback(context),
          icon: const Icon(Icons.star_outline),
          label: const Text('Leave Feedback'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kAccentColor,
            side: const BorderSide(color: kAccentColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    // Cancel button for Pending transactions (initiator)
    else if (isInitiator && widget.transaction.isPending) {
      actionContent = SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () => _handleCancel(context, provider),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel Request'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    if (actionContent == null) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(child: actionContent),
    );
  }

  // --- Action Handlers ---

  Future<void> _handleAccept(
    BuildContext context,
    TransactionProvider provider,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      'Accept Transaction',
      'Are you sure you want to accept this ${widget.transaction.typeLabel.toLowerCase()}?',
    );

    if (confirmed == true) {
      final success = await provider.acceptTransaction(widget.transaction.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction accepted!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to accept'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDecline(
    BuildContext context,
    TransactionProvider provider,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      'Decline Transaction',
      'Are you sure you want to decline this ${widget.transaction.typeLabel.toLowerCase()}?',
      isDestructive: true,
    );

    if (confirmed == true) {
      final success = await provider.declineTransaction(widget.transaction.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction declined'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to decline'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleCancel(
    BuildContext context,
    TransactionProvider provider,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      'Cancel Request',
      'Are you sure you want to cancel this ${widget.transaction.typeLabel.toLowerCase()}?',
      isDestructive: true,
    );

    if (confirmed == true) {
      final success = await provider.cancelTransaction(widget.transaction.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to cancel'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleComplete(
    BuildContext context,
    TransactionProvider provider,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      'Complete Transaction',
      'Are you sure you want to mark this ${widget.transaction.typeLabel.toLowerCase()} as completed?',
    );

    if (confirmed == true) {
      final success = await provider.completeTransaction(widget.transaction.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction completed!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to complete'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaymentConfirmationScreen(transaction: widget.transaction),
      ),
    );
  }

  void _navigateToFeedback(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubmitFeedbackScreen(transaction: widget.transaction),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String message, {
    bool isDestructive = false,
  }) {
    return ModernDialog.show<bool>(
      context,
      title: title,
      description: message,
      icon: isDestructive ? Icons.warning_amber_rounded : Icons.help_outline,
      iconColor: isDestructive ? Colors.red : kPrimaryColor,
      isDestructive: isDestructive,
      primaryButtonText: 'Yes',
      onPrimaryPressed: () => Navigator.pop(context, true),
      secondaryButtonText: 'No',
    );
  }

  // --- Helper Methods ---

  IconData _getTypeIcon() {
    switch (widget.transaction.type) {
      case 'job_application':
        return Icons.work_outline;
      case 'service_booking':
        return Icons.build_outlined;
      case 'rental_request':
        return Icons.handyman_outlined;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getTypeColor() {
    switch (widget.transaction.type) {
      case 'job_application':
        return Colors.blue;
      case 'service_booking':
        return Colors.orange;
      case 'rental_request':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.transaction.status) {
      case 'Pending':
        return Icons.hourglass_empty;
      case 'Accepted':
        return Icons.thumb_up;
      case 'In Progress':
        return Icons.autorenew;
      case 'Completed':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor() {
    switch (widget.transaction.status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.blue;
      case 'In Progress':
        return Colors.purple;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
