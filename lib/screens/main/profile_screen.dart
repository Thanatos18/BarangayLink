import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart'; // Relative import
import '../../providers/user_provider.dart'; // Relative import
import '../../widgets/custom_app_bar.dart'; // Relative import
import '../auth/login_screen.dart'; // Relative import

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    // If user is null, show loader.
    // NOTE: This is what causes the issue during logout if we don't navigate first.
    if (user == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'My Profile'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'My Profile'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    // Use .withValues for newer Flutter versions, or .withOpacity for older
                    backgroundColor: kPrimaryColor.withOpacity(0.2),
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      // Use .withValues or .withOpacity based on your Flutter version
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
            ),
            const SizedBox(height: 32),

            // Info Section
            _buildInfoTile(Icons.email, 'Email', user.email),
            _buildInfoTile(Icons.phone, 'Contact', user.contactNumber),

            const Divider(height: 32, thickness: 1),

            // Menu Items
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('My Listings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to listings
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Transaction History'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to history
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to settings
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
                  // Navigate to admin
                },
              ),
            ],

            const SizedBox(height: 32),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  onPressed: () {
                    // 1. Navigate IMMEDIATELY to LoginScreen.
                    // This removes the ProfileScreen from the stack, so it won't try to rebuild
                    // with a null user when the provider updates.
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );

                    // 2. Perform the actual logout logic in the background.
                    // The user is already on the login screen, so they won't see any "null user" loading state.
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
            ),
            const SizedBox(height: 24),
          ],
        ),
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
}
