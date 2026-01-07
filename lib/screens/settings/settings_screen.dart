import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/modern_dialog.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSettingCard([
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive app notifications'),
              value: userProvider.currentUser?.pushNotificationsEnabled ?? true,
              onChanged: (value) {
                userProvider.updateNotificationSettings(
                  pushNotificationsEnabled: value,
                  emailNotificationsEnabled:
                      userProvider.currentUser?.emailNotificationsEnabled ??
                          true,
                );
              },
              secondary: const Icon(Icons.notifications),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive email updates'),
              value:
                  userProvider.currentUser?.emailNotificationsEnabled ?? true,
              onChanged: (value) {
                userProvider.updateNotificationSettings(
                  pushNotificationsEnabled:
                      userProvider.currentUser?.pushNotificationsEnabled ??
                          true,
                  emailNotificationsEnabled: value,
                );
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

    ModernDialog.show(
      context,
      title: 'Change Password',
      description:
          'A password reset link will be sent to ${user.email}. Are you sure?',
      icon: Icons.lock_reset,
      primaryButtonText: 'Send Email',
      onPrimaryPressed: () async {
        Navigator.pop(context);
        try {
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
      secondaryButtonText: 'Cancel',
    );
  }

  void _showPrivacyPolicy() {
    ModernDialog.show(
      context,
      title: 'Privacy Policy',
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
          textAlign: TextAlign.justify,
        ),
      ),
      icon: Icons.privacy_tip,
      primaryButtonText: 'Close',
      onPrimaryPressed: () => Navigator.pop(context),
    );
  }

  void _showTermsOfService() {
    ModernDialog.show(
      context,
      title: 'Terms of Service',
      content: const SingleChildScrollView(
        child: Text(
          'By using BarangayLink, you agree to:\n\n'
          '• Provide accurate information\n'
          '• Treat other users with respect\n'
          '• Complete transactions in good faith\n'
          '• Report inappropriate content\n'
          '• Not use the platform for illegal activities\n\n'
          'Violation of these terms may result in account suspension.',
          textAlign: TextAlign.justify,
        ),
      ),
      icon: Icons.description,
      primaryButtonText: 'Close',
      onPrimaryPressed: () => Navigator.pop(context),
    );
  }

  void _showHelpSupport() {
    ModernDialog.show(
      context,
      title: 'Help & Support',
      icon: Icons.help,
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Need help? Contact us:'),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.email, size: 20, color: Colors.grey),
              SizedBox(width: 12),
              Text('support@barangaylink.com'),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.phone, size: 20, color: Colors.grey),
              SizedBox(width: 12),
              Text('+63 912 345 6789'),
            ],
          ),
        ],
      ),
      primaryButtonText: 'Close',
      onPrimaryPressed: () => Navigator.pop(context),
    );
  }

  Future<void> _confirmLogout(UserProvider userProvider) async {
    final confirmed = await ModernDialog.show<bool>(
      context,
      title: 'Logout',
      description: 'Are you sure you want to logout?',
      icon: Icons.logout,
      iconColor: Colors.red,
      isDestructive: true,
      primaryButtonText: 'Logout',
      onPrimaryPressed: () => Navigator.pop(context, true),
      secondaryButtonText: 'Cancel',
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
