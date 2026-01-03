import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/favorite.dart';
import '../../services/firebase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../details/job_detail_screen.dart';
import '../details/service_detail_screen.dart';
import '../details/rental_detail_screen.dart';
import '../../constants/app_constants.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      Provider.of<FavoritesProvider>(
        context,
        listen: false,
      ).startListening(user.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Favorites',
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Jobs'),
            Tab(text: 'Services'),
            Tab(text: 'Rentals'),
          ],
        ),
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildFavoritesList(provider.jobFavorites),
              _buildFavoritesList(provider.serviceFavorites),
              _buildFavoritesList(provider.rentalFavorites),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFavoritesList(List<FavoriteModel> favorites) {
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: kPrimaryColor.withOpacity(0.1),
              child: Icon(
                _getIconForType(favorite.itemType),
                color: kPrimaryColor,
              ),
            ),
            title: Text(
              favorite.itemTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Added on ${_formatDate(favorite.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                _confirmRemove(context, favorite);
              },
            ),
            onTap: () {
              _navigateToDetail(context, favorite);
            },
          ),
        );
      },
    );
  }

  void _confirmRemove(BuildContext context, FavoriteModel favorite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites?'),
        content: Text(
          'Are you sure you want to remove "${favorite.itemTitle}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<FavoritesProvider>(
                context,
                listen: false,
              ).toggleFavorite(favorite);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToDetail(
    BuildContext context,
    FavoriteModel favorite,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final FirebaseService firebaseService = FirebaseService();

      if (favorite.isJob) {
        final job = await firebaseService.getJob(favorite.itemId);
        if (context.mounted) {
          Navigator.pop(context); // Dismiss loading
          if (job != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
            );
          } else {
            _showItemNotFound(context);
          }
        }
      } else if (favorite.isService) {
        final service = await firebaseService.getService(favorite.itemId);
        if (context.mounted) {
          Navigator.pop(context); // Dismiss loading
          if (service != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceDetailScreen(service: service),
              ),
            );
          } else {
            _showItemNotFound(context);
          }
        }
      } else if (favorite.isRental) {
        final rental = await firebaseService.getRental(favorite.itemId);
        if (context.mounted) {
          Navigator.pop(context); // Dismiss loading
          if (rental != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RentalDetailScreen(rental: rental),
              ),
            );
          } else {
            _showItemNotFound(context);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading item: $e')));
      }
    }
  }

  void _showItemNotFound(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item no longer exists')));
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'job':
        return Icons.work;
      case 'service':
        return Icons.handyman;
      case 'rental':
        return Icons.home;
      default:
        return Icons.star;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
