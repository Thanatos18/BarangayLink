import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/report.dart';
import '../providers/admin_provider.dart';
import '../providers/user_provider.dart';
import 'modern_dialog.dart';

/// A reusable dialog for reporting content.
class ReportDialog extends StatefulWidget {
  final String itemId;
  final String itemType; // 'job', 'service', 'rental'
  final String itemTitle;

  const ReportDialog({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
  });

  /// Show the report dialog
  static Future<bool?> show(
    BuildContext context, {
    required String itemId,
    required String itemType,
    required String itemTitle,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReportDialog(
        itemId: itemId,
        itemType: itemType,
        itemTitle: itemTitle,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModernDialog(
      title: 'Report Content',
      icon: Icons.flag,
      iconColor: Colors.red,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item being reported
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getTypeIcon(widget.itemType),
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.itemTitle,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason Selection
            const Text(
              'Why are you reporting this?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...ReportReasons.reasons.map((reason) {
              return RadioListTile<String>(
                title: Text(reason, style: const TextStyle(fontSize: 14)),
                value: reason,
                groupValue: _selectedReason,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
              );
            }),

            const SizedBox(height: 8),

            // Additional Details
            TextField(
              controller: _detailsController,
              decoration: InputDecoration(
                labelText: 'Additional details (optional)',
                hintText: 'Provide more context...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      secondaryButtonText: 'Cancel',
      primaryButtonText: _isSubmitting ? 'Submitting...' : 'Submit Report',
      onPrimaryPressed:
          (_selectedReason == null || _isSubmitting) ? null : _submitReport,
      isDestructive: true,
    );
  }

  Future<void> _submitReport() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    if (currentUser == null || _selectedReason == null) return;

    setState(() => _isSubmitting = true);

    final success = await adminProvider.submitReport(
      reportedItemId: widget.itemId,
      reportedItemType: widget.itemType,
      reportedItemTitle: widget.itemTitle,
      reportedBy: currentUser.uid,
      reportedByName: currentUser.name,
      reason: _selectedReason!,
      additionalDetails:
          _detailsController.text.isNotEmpty ? _detailsController.text : null,
    );

    if (mounted) {
      Navigator.pop(context, success);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'job':
        return Icons.work;
      case 'service':
        return Icons.build;
      case 'rental':
        return Icons.handyman;
      default:
        return Icons.article;
    }
  }
}
