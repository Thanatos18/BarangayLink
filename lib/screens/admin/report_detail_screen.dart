import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../models/job.dart';
import '../../models/service.dart';
import '../../models/rental.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/custom_app_bar.dart';

class ReportDetailScreen extends StatefulWidget {
  final ReportModel report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoadingContent = true;
  dynamic _contentItem;
  String? _contentError;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    setState(() {
      _isLoadingContent = true;
      _contentError = null;
    });

    try {
      // 1. Fetch the reported item based on type
      if (widget.report.reportedItemType == 'job') {
        _contentItem = await _firebaseService.getJob(
          widget.report.reportedItemId,
        );
      } else if (widget.report.reportedItemType == 'service') {
        _contentItem = await _firebaseService.getService(
          widget.report.reportedItemId,
        );
      } else if (widget.report.reportedItemType == 'rental') {
        _contentItem = await _firebaseService.getRental(
          widget.report.reportedItemId,
        );
      } else if (widget.report.reportedItemType == 'user') {
        _contentItem = await _firebaseService.getUserDocument(
          widget.report.reportedItemId,
        );
      }

      // 2. Fetch the reported user (if item is not a user profile itself)
      // Note: In real app, we might need to fetch the owner of the item.
      // For simplified logic, if it's a user report, _contentItem is the user.
    } catch (e) {
      _contentError = 'Error loading content: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final currentUser = Provider.of<UserProvider>(context).currentUser;

    if (currentUser == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Report Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            _buildStatusHeader(),
            const SizedBox(height: 24),

            // Report Info
            _buildSectionTitle('Report Information'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow('Reason', widget.report.reason),
              if (widget.report.additionalDetails != null)
                _buildInfoRow('Details', widget.report.additionalDetails!),
              _buildInfoRow(
                'Reported By',
                widget.report.reportedByName ?? 'Unknown',
              ),
              _buildInfoRow('Date', _formatDate(widget.report.createdAt)),
            ]),
            const SizedBox(height: 24),

            // Content Preview
            _buildSectionTitle('Reported Content'),
            const SizedBox(height: 12),
            _buildContentPreview(),
            const SizedBox(height: 32),

            // Actions
            if (widget.report.isPending)
              _buildActionButtons(adminProvider, currentUser.uid),

            if (!widget.report.isPending) _buildResolutionInfo(),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusHeader() {
    Color color;
    IconData icon;
    String text;

    if (widget.report.isResolved) {
      color = Colors.green;
      icon = Icons.check_circle;
      text = 'RESOLVED';
    } else if (widget.report.isDismissed) {
      color = Colors.grey;
      icon = Icons.cancel;
      text = 'DISMISSED';
    } else {
      color = Colors.orange;
      icon = Icons.warning;
      text = 'PENDING REVIEW';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview() {
    if (_isLoadingContent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_contentError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Text(_contentError!)),
          ],
        ),
      );
    }

    if (_contentItem == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Content no longer exists (It may have been deleted).',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    // Render content based on type
    if (widget.report.reportedItemType == 'job' && _contentItem is JobModel) {
      final job = _contentItem as JobModel;
      return _buildContentCard(
        title: job.title,
        subtitle: job.description,
        icon: Icons.work,
        color: Colors.blue,
      );
    } else if (widget.report.reportedItemType == 'service' &&
        _contentItem is ServiceModel) {
      final service = _contentItem as ServiceModel;
      return _buildContentCard(
        title: service.name, // Fixed: serviceName -> name
        subtitle: service.description,
        icon: Icons.build,
        color: Colors.orange,
      );
    } else if (widget.report.reportedItemType == 'rental' &&
        _contentItem is RentalModel) {
      final rental = _contentItem as RentalModel;
      return _buildContentCard(
        title: rental.itemName,
        subtitle: rental.description,
        icon: Icons.handyman,
        color: Colors.purple,
      );
    } else if (widget.report.reportedItemType == 'user' &&
        _contentItem is UserModel) {
      final user = _contentItem as UserModel;
      return _buildContentCard(
        title: user.name,
        subtitle: user.email,
        icon: Icons.person,
        color: Colors.red,
      );
    }

    return const Text('Unknown content type');
  }

  Widget _buildContentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AdminProvider provider, String adminUid) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _confirmDelete(provider, adminUid),
            icon: const Icon(Icons.delete),
            label: const Text('Delete Content'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _confirmDismiss(provider, adminUid),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Dismiss Report'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _confirmWarn(provider, adminUid),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Warn User'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResolutionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resolution Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Resolved By: ${widget.report.resolvedBy ?? "Admin"}'),
          Text('Action: ${widget.report.resolution ?? "None"}'),
          if (widget.report.resolvedAt != null)
            Text('Date: ${_formatDate(widget.report.resolvedAt!)}'),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AdminProvider provider, String adminUid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content?'),
        content: const Text(
          'This will permanently remove the content. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.deleteReportedContent(
        widget.report,
        adminUid,
      );
      if (mounted) {
        if (success) {
          Navigator.pop(context); // Go back
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete content')),
          );
        }
      }
    }
  }

  Future<void> _confirmDismiss(AdminProvider provider, String adminUid) async {
    final success = await provider.dismissReport(widget.report.id, adminUid);
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report dismissed')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to dismiss')));
      }
    }
  }

  Future<void> _confirmWarn(AdminProvider provider, String adminUid) async {
    final success = await provider.resolveReport(
      widget.report.id,
      'User Warned',
      adminUid,
    );
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User was warned')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to warn user')));
      }
    }
  }
}
