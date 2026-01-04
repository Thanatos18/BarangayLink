import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/job.dart';
import '../../models/service.dart';
import '../../models/rental.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/rentals_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../details/job_detail_screen.dart';
import '../details/service_detail_screen.dart';
import '../details/rental_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'jobs', 'services', 'rentals'
  bool _isSearching = false;

  List<dynamic> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final jobsProvider = Provider.of<JobsProvider>(context, listen: false);
    final servicesProvider = Provider.of<ServicesProvider>(
      context,
      listen: false,
    );
    final rentalsProvider = Provider.of<RentalsProvider>(
      context,
      listen: false,
    );

    final queryLower = query.toLowerCase();
    final List<dynamic> results = [];

    // Search Jobs
    if (_selectedFilter == 'all' || _selectedFilter == 'jobs') {
      for (var job in jobsProvider.allJobs) {
        if (job.title.toLowerCase().contains(queryLower) ||
            job.description.toLowerCase().contains(queryLower) ||
            job.barangay.toLowerCase().contains(queryLower)) {
          results.add({'type': 'job', 'item': job});
        }
      }
    }

    // Search Services
    if (_selectedFilter == 'all' || _selectedFilter == 'services') {
      for (var service in servicesProvider.allServices) {
        if (service.name.toLowerCase().contains(queryLower) ||
            service.description.toLowerCase().contains(queryLower) ||
            service.barangay.toLowerCase().contains(queryLower)) {
          results.add({'type': 'service', 'item': service});
        }
      }
    }

    // Search Rentals
    if (_selectedFilter == 'all' || _selectedFilter == 'rentals') {
      for (var rental in rentalsProvider.allRentals) {
        if (rental.itemName.toLowerCase().contains(queryLower) ||
            rental.description.toLowerCase().contains(queryLower) ||
            rental.barangay.toLowerCase().contains(queryLower)) {
          results.add({'type': 'rental', 'item': rental});
        }
      }
    }

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Search',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Filter Chips
          _buildFilterChips(),

          // Results
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search jobs, services, rentals...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: _performSearch,
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All', 'icon': Icons.search},
      {'key': 'jobs', 'label': 'Jobs', 'icon': Icons.work},
      {'key': 'services', 'label': 'Services', 'icon': Icons.build},
      {'key': 'rentals', 'label': 'Rentals', 'icon': Icons.handyman},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  filter['icon'] as IconData,
                  size: 18,
                  color: isSelected ? Colors.white : kPrimaryColor,
                ),
                label: Text(filter['label'] as String),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter['key'] as String;
                  });
                  _performSearch(_searchController.text);
                },
                selectedColor: kPrimaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                checkmarkColor: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Start typing to search',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final type = result['type'] as String;
    final item = result['item'];

    String title;
    String subtitle;
    String barangay;
    IconData icon;
    Color color;
    VoidCallback onTap;

    switch (type) {
      case 'job':
        final job = item as JobModel;
        title = job.title;
        subtitle = job.description;
        barangay = job.barangay;
        icon = Icons.work;
        color = Colors.blue;
        onTap = () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
            );
        break;
      case 'service':
        final service = item as ServiceModel;
        title = service.name;
        subtitle = service.description;
        barangay = service.barangay;
        icon = Icons.build;
        color = Colors.orange;
        onTap = () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceDetailScreen(service: service),
              ),
            );
        break;
      case 'rental':
        final rental = item as RentalModel;
        title = rental.itemName;
        subtitle = rental.description;
        barangay = rental.barangay;
        icon = Icons.handyman;
        color = Colors.purple;
        onTap = () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => RentalDetailScreen(rental: rental)),
            );
        break;
      default:
        return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Type Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          barangay,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
