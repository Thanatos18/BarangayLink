import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSettingCard([
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive app notifications'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
              secondary: const Icon(Icons.notifications),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive email updates'),
              value: _emailNotifications,
              onChanged: (value) {
                setState(() => _emailNotifications = value);
              },
              secondary: const Icon(Icons.email),
            ),
          ]),

          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingCard([
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Already accessible from profile screen
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showPasswordChangeDialog();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showPrivacyPolicy();
              },
            ),
          ]),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildSettingCard([
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('App Version'),
              subtitle: const Text('1.0.0'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showTermsOfService();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showHelpSupport();
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Logout Section
          _buildSettingCard([
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => _confirmLogout(userProvider),
            ),
          ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  void _showPasswordChangeDialog() {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Text(
          'A password reset link will be sent to ${user.email}. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Initialize AuthService directly since it's a stateless service wrapper
                // or retrieve if provided. For now, creating instance as per other files.
                // However, cleaner to import it.
                // We need to import AuthService at the top.
                // Assuming we will add the import.
                await Provider.of<UserProvider>(
                  context,
                  listen: false,
                ).sendPasswordResetEmail();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send email: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'BarangayLink respects your privacy. We collect minimal data necessary '
            'to provide our services. Your personal information is stored securely '
            'and never shared with third parties without your consent.\n\n'
            'We use your data to:\n'
            '• Match you with jobs, services, and rentals in your barangay\n'
            '• Facilitate transactions between users\n'
            '• Send relevant notifications\n\n'
            'You can request data deletion at any time.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using BarangayLink, you agree to:\n\n'
            '• Provide accurate information\n'
            '• Treat other users with respect\n'
            '• Complete transactions in good faith\n'
            '• Report inappropriate content\n'
            '• Not use the platform for illegal activities\n\n'
            'Violation of these terms may result in account suspension.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact us:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, size: 20),
                SizedBox(width: 8),
                Text('support@barangaylink.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 20),
                SizedBox(width: 8),
                Text('+63 912 345 6789'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(UserProvider userProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await userProvider.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
