import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home_screen.dart';
import '../../providers/notification_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/user_provider.dart';
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
        Provider.of<FavoritesProvider>(
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
      // Removed AppBar from here to handle it in individual screens (Jobs, Services, etc.)
      // IndexedStack preserves the state of each tab
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _navigateToTab,
      ),
    );
  }
}
