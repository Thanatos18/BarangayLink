import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home_screen.dart';
import '../../constants/app_constants.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../notifications/notifications_screen.dart';
import '../search/search_screen.dart';
import 'jobs_screen.dart';
import 'profile_screen.dart';
import 'rentals_screen.dart';
import 'services_screen.dart';
import '../../widgets/bottom_nav_bar.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  // List of screens for navigation
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      // Pass the callback to HomeScreen so it can control the tabs
      HomeScreen(onNavigate: _navigateToTab),
      const JobsScreen(),
      const ServicesScreen(),
      const RentalsScreen(),
      const ProfileScreen(),
    ];

    // Initialize notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(
        context,
        listen: false,
      ).currentUser;
      if (user != null) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).startListening(user.uid);
      }
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      // IndexedStack preserves the state of each tab
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _navigateToTab,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'BarangayLink',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Search Button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
        ),
        // Notification Button with Badge
        Consumer<NotificationProvider>(
          builder: (context, notifProvider, child) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (notifProvider.hasUnread)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        notifProvider.unreadCount > 9
                            ? '9+'
                            : '${notifProvider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
