import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/rentals_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../details/job_detail_screen.dart';
import '../details/service_detail_screen.dart';
import '../details/rental_detail_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context).currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your listings')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Listings',
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Jobs'),
            Tab(text: 'Services'),
            Tab(text: 'Rentals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJobsList(currentUser.uid),
          _buildServicesList(currentUser.uid),
          _buildRentalsList(currentUser.uid),
        ],
      ),
    );
  }

  Widget _buildJobsList(String userId) {
    return Consumer<JobsProvider>(
      builder: (context, provider, _) {
        final myJobs = provider.allJobs
            .where((job) => job.postedBy == userId)
            .toList();

        if (myJobs.isEmpty) {
          return _buildEmptyState('No jobs posted yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myJobs.length,
          itemBuilder: (context, index) {
            final job = myJobs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  job.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Posted on ${_formatDate(job.createdAt)}'),
                trailing: Chip(
                  label: Text(
                    job.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(job.status),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailScreen(job: job),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildServicesList(String userId) {
    return Consumer<ServicesProvider>(
      builder: (context, provider, _) {
        final myServices = provider.allServices
            .where((s) => s.providerId == userId)
            .toList();

        if (myServices.isEmpty) {
          return _buildEmptyState('No services offered yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myServices.length,
          itemBuilder: (context, index) {
            final service = myServices[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  service.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(service.category),
                trailing: Chip(
                  label: Text(
                    service.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(service.status),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceDetailScreen(service: service),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRentalsList(String userId) {
    return Consumer<RentalsProvider>(
      builder: (context, provider, _) {
        final myRentals = provider.allRentals
            .where((r) => r.ownerId == userId)
            .toList();

        if (myRentals.isEmpty) {
          return _buildEmptyState('No items listed for rent');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myRentals.length,
          itemBuilder: (context, index) {
            final rental = myRentals[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  rental.itemName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('₱${rental.rentPrice}/day'),
                trailing: Chip(
                  label: Text(
                    rental.isAvailable ? 'Available' : 'Rented',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: rental.isAvailable
                      ? Colors.green
                      : Colors.orange,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RentalDetailScreen(rental: rental),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'available':
        return Colors.green;
      case 'in progress':
      case 'rented':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'unavailable':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
