import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/rental.dart';
import '../../providers/rentals_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../details/rental_detail_screen.dart';
import '../create/create_rental_screen.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
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
      appBar: const CustomAppBar(title: 'Rentals'),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          // Filter Toggle Button
          _buildFilterToggle(),
          // Filter Chips (collapsible)
          if (_showFilters) _buildFilterSection(),
          // Rentals List
          Expanded(child: _buildRentalsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateRental(context),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('List Item', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search rentals...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<RentalsProvider>().setSearchQuery('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          context.read<RentalsProvider>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildFilterToggle() {
    final rentalsProvider = context.watch<RentalsProvider>();
    final hasActiveFilters = rentalsProvider.selectedBarangay != null ||
        rentalsProvider.selectedCategory != null ||
        rentalsProvider.showAvailableOnly == true ||
        rentalsProvider.selectedCondition != null;

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
                rentalsProvider.clearFilters();
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
    final rentalsProvider = context.watch<RentalsProvider>();
    return DropdownButton<String>(
      value: rentalsProvider.sortBy,
      underline: const SizedBox(),
      icon: const Icon(Icons.sort),
      items: const [
        DropdownMenuItem(value: 'newest', child: Text('Newest')),
        DropdownMenuItem(value: 'highest_price', child: Text('Highest Price')),
        DropdownMenuItem(value: 'lowest_price', child: Text('Lowest Price')),
      ],
      onChanged: (value) {
        if (value != null) {
          rentalsProvider.setSortBy(value);
        }
      },
    );
  }

  Widget _buildFilterSection() {
    final rentalsProvider = context.watch<RentalsProvider>();

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
                selected: rentalsProvider.showAvailableOnly == true,
                onSelected: (selected) {
                  rentalsProvider.setAvailabilityFilter(selected ? true : null);
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
                  value: rentalsProvider.selectedCategory,
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
                    ...rentalsProvider.categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    rentalsProvider.setCategoryFilter(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Condition Dropdown
          Row(
            children: [
              const Text('Condition: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: rentalsProvider.selectedCondition,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  hint: const Text('Any Condition'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Any Condition'),
                    ),
                    ...RentalsProvider.conditionOptions.map((cond) {
                      return DropdownMenuItem<String>(
                        value: cond,
                        child: Text(cond),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    rentalsProvider.setConditionFilter(value);
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
                  value: rentalsProvider.selectedBarangay,
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
                    rentalsProvider.setBarangayFilter(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentalsList() {
    final rentalsProvider = context.watch<RentalsProvider>();

    if (rentalsProvider.isLoading && rentalsProvider.filteredRentals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rentalsProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(rentalsProvider.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                rentalsProvider.clearFilters();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (rentalsProvider.filteredRentals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No rentals found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or list an item for rent',
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
        itemCount: rentalsProvider.filteredRentals.length,
        itemBuilder: (context, index) {
          final rental = rentalsProvider.filteredRentals[index];
          return _buildRentalCard(rental);
        },
      ),
    );
  }

  Widget _buildRentalCard(RentalModel rental) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToRentalDetail(context, rental),
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
                      rental.itemName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(rental.isAvailable),
                ],
              ),
              const SizedBox(height: 8),
              // Category and Condition
              Row(
                children: [
                  Chip(
                    label: Text(rental.category),
                    backgroundColor: kAccentColor.withValues(alpha: 0.3),
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  _buildConditionChip(rental.condition),
                ],
              ),
              const SizedBox(height: 8),
              // Description preview
              Text(
                rental.description,
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Footer: Price, Owner, Barangay
              Row(
                children: [
                  // Price
                  Icon(Icons.payments, size: 16, color: kPrimaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '₱${rental.rentPrice.toStringAsFixed(0)}/day',
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
                      rental.barangay,
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

  Widget _buildStatusBadge(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Rented',
        style: TextStyle(
          color: isAvailable ? Colors.green.shade700 : Colors.orange.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildConditionChip(String condition) {
    Color bgColor;
    Color textColor;

    switch (condition) {
      case 'Good':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'Fair':
        bgColor = Colors.yellow.shade50;
        textColor = Colors.orange.shade700;
        break;
      case 'Needs Repair':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        condition,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToRentalDetail(BuildContext context, RentalModel rental) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentalDetailScreen(rental: rental),
      ),
    );
  }

  void _navigateToCreateRental(BuildContext context) {
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to list an item')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateRentalScreen(),
      ),
    );
  }
}
