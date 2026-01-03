import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/feedback.dart';
import '../../providers/user_provider.dart';
import '../../providers/feedback_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../auth/login_screen.dart';
import '../transaction/transaction_history_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/feedback_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../favorites/favorites_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/my_listings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeedbackData();
    });
  }

  void _loadFeedbackData() {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      Provider.of<FeedbackProvider>(
        context,
        listen: false,
      ).startListening(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final feedbackProvider = Provider.of<FeedbackProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'My Profile'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutConfirmation(context, userProvider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Log Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await userProvider.refreshUser();
          _loadFeedbackData();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Profile Header with Avatar
              _buildProfileHeader(user),
              const SizedBox(height: 16),

              // Rating Section
              _buildRatingSection(feedbackProvider, user.uid, user.name),
              const SizedBox(height: 24),

              // Stats Section
              _buildStatsSection(feedbackProvider),
              const SizedBox(height: 16),

              // Info Section
              _buildInfoTile(Icons.email, 'Email', user.email),
              _buildInfoTile(Icons.phone, 'Contact', user.contactNumber),

              const Divider(height: 32, thickness: 1),

              // Recent Feedback Section
              _buildRecentFeedbackSection(
                feedbackProvider,
                user.uid,
                user.name,
              ),

              const Divider(height: 32, thickness: 1),

              // Menu Items
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('My Favorites'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('My Listings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyListingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Transaction History'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionHistoryScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),

              if (user.isAdmin) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Admin Dashboard',
                    style: TextStyle(color: Colors.red),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 32),

              // Logout Button
              _buildLogoutButton(userProvider),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: kPrimaryColor.withOpacity(0.2),
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kAccentColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              user.barangay,
              style: TextStyle(
                color: Colors.brown[800],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(
    FeedbackProvider provider,
    String userId,
    String userName,
  ) {
    if (provider.totalReviews == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FeedbackScreen(userId: userId, userName: userName),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kPrimaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Star Rating Display
            Row(
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isFullStar = starIndex <= provider.averageRating.floor();
                final isHalfStar =
                    starIndex == provider.averageRating.floor() + 1 &&
                    provider.averageRating % 1 >= 0.5;

                return Icon(
                  isFullStar
                      ? Icons.star
                      : isHalfStar
                      ? Icons.star_half
                      : Icons.star_border,
                  color: kAccentColor,
                  size: 24,
                );
              }),
            ),
            const SizedBox(width: 12),
            Text(
              '${provider.averageRating.toStringAsFixed(1)}/5',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              '(${provider.totalReviews} reviews)',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(FeedbackProvider provider) {
    final stats = provider.userStats;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Jobs', stats['jobs'] ?? 0, Icons.work),
          _buildStatItem('Services', stats['services'] ?? 0, Icons.build),
          _buildStatItem('Rentals', stats['rentals'] ?? 0, Icons.handyman),
          _buildStatItem(
            'Transactions',
            stats['transactions'] ?? 0,
            Icons.receipt,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kPrimaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentFeedbackSection(
    FeedbackProvider provider,
    String userId,
    String userName,
  ) {
    final recentFeedback = provider.recentFeedback;

    if (recentFeedback.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Text('No reviews yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Reviews',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FeedbackScreen(userId: userId, userName: userName),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        ...recentFeedback.map((feedback) => _buildFeedbackCard(feedback)),
      ],
    );
  }

  Widget _buildFeedbackCard(FeedbackModel feedback) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Star Rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < feedback.rating ? Icons.star : Icons.star_border,
                color: kAccentColor,
                size: 16,
              );
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedback.reviewedByName ?? 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (feedback.review.isNotEmpty)
                  Text(
                    feedback.review,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[700], size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
        ],
      ),
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    UserProvider userProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
              userProvider.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Log Out'),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
            userProvider.logout();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
