import 'package:flutter/material.dart';
import '../constants/app_constants.dart'; // Changed to relative import

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: Colors.white,
      // Fixed: Use .withValues(alpha: ...) for modern Flutter compatibility
      indicatorColor: kPrimaryColor.withValues(alpha: 0.2),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: kPrimaryColor),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.work_outline),
          selectedIcon: Icon(Icons.work, color: kPrimaryColor),
          label: 'Jobs',
        ),
        NavigationDestination(
          icon: Icon(Icons.handyman_outlined),
          selectedIcon: Icon(Icons.handyman, color: kPrimaryColor),
          label: 'Services',
        ),
        NavigationDestination(
          icon: Icon(Icons.build_outlined),
          selectedIcon: Icon(Icons.build, color: kPrimaryColor),
          label: 'Rentals',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: kPrimaryColor),
          label: 'Profile',
        ),
      ],
    );
  }
}
