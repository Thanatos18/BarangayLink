import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/rental.dart';
import '../../models/user.dart';
import '../../services/firebase_service.dart';
import '../../providers/rentals_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/favorite.dart';
import '../create/edit_rental_screen.dart';

class RentalDetailScreen extends StatelessWidget {
  final RentalModel rental;

  const RentalDetailScreen({super.key, required this.rental});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.currentUser;
    final isOwner = currentUser?.uid == rental.ownerId;
    final isAdmin = currentUser?.isAdmin ?? false;
    final canModify = isOwner || isAdmin;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Rental Details', style: TextStyle(color: Colors.white)),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, _) {
              final isFav = favoritesProvider.isFavorite(rental.id);
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
                    itemId: rental.id,
                    itemType: 'rental',
                    itemTitle: rental.itemName,
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
          if (canModify)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit Rental'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'toggle_availability',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Toggle Availability'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Rental'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          // Status and Condition badges
          Row(
            children: [
              _buildStatusBadge(rental.isAvailable),
              const SizedBox(width: 8),
              _buildConditionBadge(rental.condition),
            ],
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            rental.itemName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Category chip
          Chip(
            label: Text(rental.category),
            backgroundColor: kAccentColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          // Price highlight
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
                  '$kCurrencySymbol${rental.rentPrice.toStringAsFixed(0)}/day',
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

  Widget _buildStatusBadge(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle_outline : Icons.pending,
            color: isAvailable ? Colors.green.shade700 : Colors.orange.shade700,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Available' : 'Rented',
            style: TextStyle(
              color:
                  isAvailable ? Colors.green.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionBadge(String condition) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (condition) {
      case 'Good':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.thumb_up_outlined;
        break;
      case 'Fair':
        bgColor = Colors.yellow.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.thumbs_up_down_outlined;
        break;
      case 'Needs Repair':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.build_outlined;
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
            condition,
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
            'Item Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Owner
          _buildDetailRow(
            icon: Icons.person,
            label: 'Owner',
            value: rental.ownerName,
          ),
          // Contact Number (Async fetch)
          FutureBuilder<UserModel?>(
            future: FirebaseService().getUserDocument(rental.ownerId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text("Loading contact info...",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              if (snapshot.hasData && snapshot.data != null) {
                return _buildDetailRow(
                  icon: Icons.phone,
                  label: 'Contact Number',
                  value: snapshot.data!.contactNumber,
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Barangay
          _buildDetailRow(
            icon: Icons.location_on,
            label: 'Barangay',
            value: rental.barangay,
          ),
          // Condition
          _buildDetailRow(
            icon: Icons.star_outline,
            label: 'Condition',
            value: rental.condition,
          ),
          // Listed date
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Listed on',
            value: _formatFullDate(rental.createdAt),
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
            rental.description,
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
    // Don't show rent button for owner or if item is not available
    if (isOwner || !rental.isAvailable) {
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
              ? () => _requestRental(context, currentUser)
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to rent this item'),
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
              Icon(Icons.shopping_cart_checkout),
              SizedBox(width: 8),
              Text(
                'Request to Rent',
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
            builder: (context) => EditRentalScreen(rental: rental),
          ),
        );
        break;
      case 'toggle_availability':
        _toggleAvailability(context);
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _toggleAvailability(BuildContext context) async {
    try {
      await context.read<RentalsProvider>().updateRental(rental.id, {
        'isAvailable': !rental.isAvailable,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              rental.isAvailable
                  ? 'Item marked as rented'
                  : 'Item marked as available',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rental'),
        content: const Text(
          'Are you sure you want to delete this rental listing? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await context.read<RentalsProvider>().deleteRental(rental.id);
                if (context.mounted) {
                  Navigator.pop(context); // Return to rentals list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rental deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting rental: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestRental(BuildContext context, dynamic currentUser) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Rental'),
        content: Text(
          'Are you sure you want to request to rent "${rental.itemName}"?\n\nThe owner will be notified and can contact you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<RentalsProvider>().requestRental(
            rentalId: rental.id,
            itemName: rental.itemName,
            ownerId: rental.ownerId,
            renterId: currentUser.uid,
            renterName: currentUser.name,
            barangay: rental.barangay,
            rentPrice: rental.rentPrice,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental request sent successfully!'),
            backgroundColor: kPrimaryColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error requesting rental: $e')));
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
