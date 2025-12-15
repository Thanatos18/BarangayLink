import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/service.dart';
import '../../providers/services_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../details/service_detail_screen.dart';
import '../create/create_service_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Barangay Services'),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          // Filter Toggle Button
          _buildFilterToggle(),
          // Filter Chips (collapsible)
          if (_showFilters) _buildFilterSection(),
          // Services List
          Expanded(child: _buildServicesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateService(context),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Offer Service', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search services...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ServicesProvider>().setSearchQuery('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          context.read<ServicesProvider>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildFilterToggle() {
    final servicesProvider = context.watch<ServicesProvider>();
    final hasActiveFilters = servicesProvider.selectedBarangay != null ||
        servicesProvider.selectedCategory != null ||
        servicesProvider.showAvailableOnly == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: hasActiveFilters ? kPrimaryColor : Colors.grey,
            ),
            label: Text(
              _showFilters ? 'Hide Filters' : 'Show Filters',
              style: TextStyle(
                color: hasActiveFilters ? kPrimaryColor : Colors.grey,
              ),
            ),
          ),
          if (hasActiveFilters)
            TextButton(
              onPressed: () {
                servicesProvider.clearFilters();
              },
              child: const Text('Clear All'),
            ),
          // Sort dropdown
          _buildSortDropdown(),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    final servicesProvider = context.watch<ServicesProvider>();
    return DropdownButton<String>(
      value: servicesProvider.sortBy,
      underline: const SizedBox(),
      icon: const Icon(Icons.sort),
      items: const [
        DropdownMenuItem(value: 'newest', child: Text('Newest')),
        DropdownMenuItem(value: 'highest_rate', child: Text('Highest Rate')),
        DropdownMenuItem(value: 'lowest_rate', child: Text('Lowest Rate')),
      ],
      onChanged: (value) {
        if (value != null) {
          servicesProvider.setSortBy(value);
        }
      },
    );
  }

  Widget _buildFilterSection() {
    final servicesProvider = context.watch<ServicesProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Availability Filter
          Row(
            children: [
              const Text('Show: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Available Only'),
                selected: servicesProvider.showAvailableOnly == true,
                onSelected: (selected) {
                  servicesProvider.setAvailabilityFilter(selected ? true : null);
                },
                selectedColor: kPrimaryColor.withValues(alpha: 0.3),
                checkmarkColor: kPrimaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Category Dropdown
          Row(
            children: [
              const Text('Category: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: servicesProvider.selectedCategory,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  hint: const Text('All Categories'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...servicesProvider.categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    servicesProvider.setCategoryFilter(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barangay Dropdown
          Row(
            children: [
              const Text('Barangay: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: servicesProvider.selectedBarangay,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  hint: const Text('All Tagum City'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Tagum City'),
                    ),
                    ...tagumBarangays.map((brgy) {
                      return DropdownMenuItem<String>(
                        value: brgy,
                        child: Text(brgy),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    servicesProvider.setBarangayFilter(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    final servicesProvider = context.watch<ServicesProvider>();

    if (servicesProvider.isLoading && servicesProvider.filteredServices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (servicesProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(servicesProvider.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                servicesProvider.clearFilters();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (servicesProvider.filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_repair_service_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No services found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or offer a new service',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: servicesProvider.filteredServices.length,
        itemBuilder: (context, index) {
          final service = servicesProvider.filteredServices[index];
          return _buildServiceCard(service);
        },
      ),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToServiceDetail(context, service),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Name + Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(service.status),
                ],
              ),
              const SizedBox(height: 8),
              // Category and Provider
              Row(
                children: [
                  Chip(
                    label: Text(service.category),
                    backgroundColor: kAccentColor.withValues(alpha: 0.3),
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'by ${service.providerName}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description preview
              Text(
                service.description,
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Footer: Rate, Barangay
              Row(
                children: [
                  // Rate
                  Icon(Icons.payments, size: 16, color: kPrimaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '₱${service.rate.toStringAsFixed(0)}/hr',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const Spacer(),
                  // Barangay
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      service.barangay,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Available':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case 'Unavailable':
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToServiceDetail(BuildContext context, ServiceModel service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(service: service),
      ),
    );
  }

  void _navigateToCreateService(BuildContext context) {
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to offer a service')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateServiceScreen(),
      ),
    );
  }
}
