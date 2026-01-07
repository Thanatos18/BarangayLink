import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/report.dart';
import '../../providers/admin_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'report_detail_screen.dart';
import '../../widgets/modern_dialog.dart';

class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({super.key});

  @override
  State<ContentModerationScreen> createState() =>
      _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(
        context,
        listen: false,
      ).startListeningToReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null || !currentUser.isAdmin) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Content Moderation'),
        body: Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Content Moderation',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(adminProvider),

          // Reports List
          Expanded(child: _buildReportsList(adminProvider, currentUser.uid)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AdminProvider provider) {
    final filters = ['all', 'pending', 'resolved', 'dismissed'];
    final labels = ['All', 'Pending', 'Resolved', 'Dismissed'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(filters.length, (index) {
            final isSelected = provider.reportFilter == filters[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(labels[index]),
                selected: isSelected,
                onSelected: (selected) {
                  provider.setReportFilter(filters[index]);
                },
                selectedColor: kPrimaryColor.withOpacity(0.2),
                checkmarkColor: kPrimaryColor,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildReportsList(AdminProvider provider, String adminUid) {
    final reports = provider.reports;

    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No reports found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return _buildReportCard(reports[index], adminUid, provider);
      },
    );
  }

  Widget _buildReportCard(
    ReportModel report,
    String adminUid,
    AdminProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTypeColor(
                      report.reportedItemType,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getTypeIcon(report.reportedItemType),
                    color: _getTypeColor(report.reportedItemType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.reportedItemTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        report.typeLabel,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(report.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Reason
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(report.reason),
                    ],
                  ),
                ),
              ],
            ),

            // Additional Details
            if (report.additionalDetails != null &&
                report.additionalDetails!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Details: ${report.additionalDetails}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Reporter Info
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Reported by ${report.reportedByName ?? 'Unknown'}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const Spacer(),
                Text(
                  _formatDate(report.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),

            // Action Buttons (only for pending reports)
            if (report.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _dismissReport(report, adminUid, provider),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Dismiss'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showActionDialog(report, adminUid, provider),
                      icon: const Icon(Icons.gavel, size: 18),
                      label: const Text('Take Action'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Resolution Info (for resolved/dismissed reports)
            if (!report.isPending && report.resolution != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      report.isResolved ? Icons.check_circle : Icons.cancel,
                      color: report.isResolved ? Colors.green : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.resolution!,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'resolved':
        color = Colors.green;
        break;
      case 'dismissed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'job':
        return Icons.work;
      case 'service':
        return Icons.build;
      case 'rental':
        return Icons.handyman;
      case 'user':
        return Icons.person;
      default:
        return Icons.flag;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'job':
        return Colors.blue;
      case 'service':
        return Colors.orange;
      case 'rental':
        return Colors.purple;
      case 'user':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _dismissReport(
    ReportModel report,
    String adminUid,
    AdminProvider provider,
  ) async {
    final confirmed = await ModernDialog.show<bool>(
      context,
      title: 'Dismiss Report',
      description:
          'Are you sure you want to dismiss this report? No action will be taken.',
      icon: Icons.close,
      iconColor: Colors.grey,
      primaryButtonText: 'Dismiss',
      onPrimaryPressed: () => Navigator.pop(context, true),
      secondaryButtonText: 'Cancel',
    );

    if (confirmed == true) {
      final success = await provider.dismissReport(report.id, adminUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Report dismissed' : 'Failed to dismiss report',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showActionDialog(
    ReportModel report,
    String adminUid,
    AdminProvider provider,
  ) async {
    final action = await ModernDialog.show<String>(
      context,
      title: 'Take Action',
      description:
          'What action do you want to take on "${report.reportedItemTitle}"?',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Content'),
            subtitle: const Text('Remove the reported item'),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: const Text('Warn User'),
            subtitle: const Text('Mark as reviewed with warning'),
            onTap: () => Navigator.pop(context, 'warn'),
          ),
        ],
      ),
      icon: Icons.gavel,
      secondaryButtonText: 'Cancel',
    );

    if (action == 'delete') {
      final success = await provider.deleteReportedContent(report, adminUid);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(report: report),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Content deleted' : 'Failed to delete content',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } else if (action == 'warn') {
      final success = await provider.resolveReport(
        report.id,
        'User warned',
        adminUid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Report resolved with warning'
                  : 'Failed to resolve report',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
