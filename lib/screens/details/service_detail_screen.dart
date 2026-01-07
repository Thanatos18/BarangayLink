import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/service.dart';
import '../../providers/services_provider.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/favorite.dart';
import '../create/edit_service_screen.dart';
import '../../providers/reports_provider.dart';
import '../../models/report.dart';
import '../../widgets/modern_dialog.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceModel service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentUser;
    final isOwner = currentUser?.uid == service.providerId;
    final isAdmin = currentUser?.isAdmin ?? false;
    final canModify = isOwner || isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details',
            style: TextStyle(color: Colors.white)),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, _) {
              final isFav = favoritesProvider.isFavorite(service.id);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please log in to favorite'),
                      ),
                    );
                    return;
                  }
                  final favorite = FavoriteModel(
                    id: '',
                    userId: currentUser.uid,
                    itemId: service.id,
                    itemType: 'service',
                    itemTitle: service.name,
                    createdAt: DateTime.now(),
                  );
                  favoritesProvider.toggleFavorite(favorite);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav ? 'Removed from favorites' : 'Added to favorites',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
          if (currentUser != null)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) {
                if (canModify) {
                  return [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit Service'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Service'),
                        ],
                      ),
                    ),
                  ];
                } else {
                  return [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Report Service'),
                        ],
                      ),
                    ),
                  ];
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            if (service.imageUrls.isNotEmpty)
              Image.network(
                service.imageUrls.first,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            // Header section
            _buildHeader(),
            const Divider(),
            // Details section
            _buildDetailsSection(),
            const Divider(),
            // Description section
            _buildDescriptionSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, currentUser, isOwner),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: kPrimaryColor.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          _buildStatusBadge(service.status),
          const SizedBox(height: 12),
          // Name
          Text(
            service.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Category chip
          Chip(
            label: Text(service.category),
            backgroundColor: kAccentColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          // Rate highlight
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimaryColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments, color: kPrimaryColor, size: 28),
                const SizedBox(width: 8),
                Text(
                  '$kCurrencySymbol${service.rate.toStringAsFixed(0)}/hr',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'Available':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      case 'Unavailable':
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        icon = Icons.cancel_outlined;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Provider
          _buildDetailRow(
            icon: Icons.person,
            label: 'Provider',
            value: service.providerName,
          ),
          // Barangay
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Barangay',
            value: service.barangay,
          ),
          // Contact
          _buildDetailRow(
            icon: Icons.phone,
            label: 'Contact',
            value: service.contactNumber,
          ),
          // Posted date
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Listed on',
            value: _formatFullDate(service.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            service.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    dynamic currentUser,
    bool isOwner,
  ) {
    // Don't show book button for owner or if service is not available
    if (isOwner || service.status != 'Available') {
      return null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: currentUser != null
              ? () => _bookService(context, currentUser)
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to book a service'),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today),
              SizedBox(width: 8),
              Text(
                'Book This Service',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditServiceScreen(service: service),
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
      case 'report':
        final user = context.read<UserProvider>().currentUser;
        if (user != null) {
          _showReportDialog(context, user);
        }
        break;
    }
  }

  void _showReportDialog(BuildContext context, UserModel currentUser) {
    final detailsController = TextEditingController();
    String selectedReason = ReportReasons.reasons.first;

    ModernDialog.show(
      context,
      title: 'Report Service',
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this service?'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedReason,
              isExpanded: true,
              items: ReportReasons.reasons.map((reason) {
                return DropdownMenuItem(value: reason, child: Text(reason));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedReason = value);
                }
              },
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(
                labelText: 'Additional Details (Optional)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      primaryButtonText: 'Submit Report',
      onPrimaryPressed: () async {
        final success = await context.read<ReportsProvider>().submitReport(
              reportedItemId: service.id,
              reportedItemType: 'service',
              reportedItemTitle: service.name,
              reportedBy: currentUser.uid,
              reportedByName: currentUser.name,
              reason: selectedReason,
              additionalDetails: detailsController.text.trim(),
            );
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Report submitted successfully'
                    : 'Failed to submit report',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      },
      secondaryButtonText: 'Cancel',
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    ModernDialog.show(
      context,
      title: 'Delete Service',
      description:
          'Are you sure you want to delete this service? This action cannot be undone.',
      icon: Icons.delete_forever,
      iconColor: Colors.red,
      isDestructive: true,
      primaryButtonText: 'Delete',
      onPrimaryPressed: () async {
        Navigator.pop(context); // Close dialog
        try {
          await context.read<ServicesProvider>().deleteService(
                service.id,
              );
          if (context.mounted) {
            Navigator.pop(context); // Return to services list
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Service deleted successfully'),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting service: $e')),
            );
          }
        }
      },
      secondaryButtonText: 'Cancel',
    );
  }

  Future<void> _bookService(BuildContext context, dynamic currentUser) async {
    // Show confirmation dialog
    final confirm = await ModernDialog.show<bool>(
      context,
      title: 'Book Service',
      description:
          'Are you sure you want to book "${service.name}"?\n\nThe service provider will be notified and can contact you.',
      icon: Icons.calendar_today,
      primaryButtonText: 'Book',
      onPrimaryPressed: () => Navigator.pop(context, true),
      secondaryButtonText: 'Cancel',
    );

    if (confirm != true) return;

    try {
      await context.read<ServicesProvider>().bookService(
            serviceId: service.id,
            serviceName: service.name,
            providerId: service.providerId,
            clientId: currentUser.uid,
            clientName: currentUser.name,
            barangay: service.barangay,
            rate: service.rate,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service booked successfully!'),
            backgroundColor: kPrimaryColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error booking service: $e')));
      }
    }
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
