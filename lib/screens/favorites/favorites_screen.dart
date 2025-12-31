import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/favorite.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/rentals_provider.dart';
import '../../providers/user_provider.dart';
import '../details/job_detail_screen.dart';
import '../details/service_detail_screen.dart';
import '../details/rental_detail_screen.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(
        context,
        listen: false,
      ).currentUser;
      if (user != null) {
        Provider.of<FavoritesProvider>(
          context,
          listen: false,
        ).startListening(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.work), text: 'Jobs'),
            Tab(icon: Icon(Icons.build), text: 'Services'),
            Tab(icon: Icon(Icons.handyman), text: 'Rentals'),
          ],
        ),
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildFavoritesList(provider.jobFavorites, 'job'),
              _buildFavoritesList(provider.serviceFavorites, 'service'),
              _buildFavoritesList(provider.rentalFavorites, 'rental'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFavoritesList(List<FavoriteModel> favorites, String type) {
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No favorite ${type}s yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon to save items',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        return _buildFavoriteCard(favorites[index]);
      },
    );
  }

  Widget _buildFavoriteCard(FavoriteModel favorite) {
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    return Dismissible(
      key: Key(favorite.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        favoritesProvider.removeFavorite(favorite.itemId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _navigateToDetail(favorite),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTypeColor(favorite.itemType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getTypeIcon(favorite.itemType),
                    color: _getTypeColor(favorite.itemType),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.itemTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Added ${_formatDate(favorite.createdAt)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    favoritesProvider.removeFavorite(favorite.itemId);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(FavoriteModel favorite) {
    switch (favorite.itemType) {
      case 'job':
        final job = Provider.of<JobsProvider>(
          context,
          listen: false,
        ).getJobById(favorite.itemId);
        if (job != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
          );
        }
        break;
      case 'service':
        final service = Provider.of<ServicesProvider>(
          context,
          listen: false,
        ).getServiceById(favorite.itemId);
        if (service != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(service: service),
            ),
          );
        }
        break;
      case 'rental':
        final rental = Provider.of<RentalsProvider>(
          context,
          listen: false,
        ).getRentalById(favorite.itemId);
        if (rental != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RentalDetailScreen(rental: rental),
            ),
          );
        }
        break;
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
        return Icons.favorite;
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
      default:
        return kPrimaryColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
