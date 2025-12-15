import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart'; // Relative import
import '../../providers/user_provider.dart'; // Relative import
import '../../providers/barangay_provider.dart'; // Relative import
import '../../widgets/custom_app_bar.dart'; // Relative import

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final barangayProvider = Provider.of<BarangayProvider>(context);
    final user = userProvider.currentUser;

    // Safety check
    if (user == null) return const SizedBox.shrink();

    // Safe First Name extraction
    String firstName = 'User';
    if (user.name.isNotEmpty) {
      firstName = user.name.split(' ')[0];
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'BarangayLink',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Header & Filter
            Container(
              padding: const EdgeInsets.all(16.0),
              color: kPrimaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maayong Adlaw, $firstName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search Bar Placeholder
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Search jobs, services, items...',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Barangay Filter Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: kPrimaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: barangayProvider.currentFilter,
                        isExpanded: true,
                        hint: const Text(
                          "All Tagum City",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text("All Tagum City (Show All)"),
                          ),
                          // Fixed: Use tagumBarangays (lowerCamelCase)
                          ...barangayProvider.tagumBarangaysList.map(
                            (b) => DropdownMenuItem<String?>(
                              value: b,
                              child: Text(b),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          barangayProvider.setFilter(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Quick Actions Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildQuickAction(
                    context,
                    'Post Job',
                    Icons.work,
                    Colors.blue,
                    () => onNavigate(1), // Go to Jobs tab
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    context,
                    'Offer Service',
                    Icons.handyman,
                    Colors.orange,
                    () => onNavigate(2), // Go to Services tab
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    context,
                    'Rent Out',
                    Icons.build,
                    Colors.purple,
                    () => onNavigate(3), // Go to Rentals tab
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Quick Stats / Filter Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                // Fixed: Use .withValues for color opacity
                color: kAccentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kAccentColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.brown),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are currently viewing listings for: \n${barangayProvider.currentFilter ?? "All Tagum City"}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. Featured Section Headers (Placeholders)
            _buildSectionHeader('Featured Jobs', () => onNavigate(1)),
            _buildPlaceholderList(),

            _buildSectionHeader('Top Services', () => onNavigate(2)),
            _buildPlaceholderList(),

            _buildSectionHeader('Recent Rentals', () => onNavigate(3)),
            _buildPlaceholderList(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(onPressed: onSeeAll, child: const Text('See All')),
        ],
      ),
    );
  }

  Widget _buildPlaceholderList() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Item ${index + 1}',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          );
        },
      ),
    );
  }
}
