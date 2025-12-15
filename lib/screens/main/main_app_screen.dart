import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home/home_screen.dart'; // Relative import
import 'jobs_screen.dart'; // Relative import
import 'profile_screen.dart'; // Relative import
import 'rentals_screen.dart'; // Relative import
import 'services_screen.dart'; // Relative import
import '../../widgets/bottom_nav_bar.dart'; // Relative import

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
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the state of each tab
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _navigateToTab,
      ),
    );
  }
}
