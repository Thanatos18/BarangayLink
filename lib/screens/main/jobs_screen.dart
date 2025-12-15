import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/job.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../details/job_detail_screen.dart';
import '../create/create_job_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
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
      appBar: const CustomAppBar(title: 'Barangay Jobs'),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          // Filter Toggle Button
          _buildFilterToggle(),
          // Filter Chips (collapsible)
          if (_showFilters) _buildFilterSection(),
          // Jobs List
          Expanded(child: _buildJobsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateJob(context),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Job', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search jobs...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<JobsProvider>().setSearchQuery('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          context.read<JobsProvider>().setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildFilterToggle() {
    final jobsProvider = context.watch<JobsProvider>();
    final hasActiveFilters = jobsProvider.selectedBarangay != null ||
        jobsProvider.selectedCategory != null ||
        jobsProvider.selectedStatus != null;

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
                jobsProvider.clearFilters();
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
    final jobsProvider = context.watch<JobsProvider>();
    return DropdownButton<String>(
      value: jobsProvider.sortBy,
      underline: const SizedBox(),
      icon: const Icon(Icons.sort),
      items: const [
        DropdownMenuItem(value: 'newest', child: Text('Newest')),
        DropdownMenuItem(value: 'highest_wage', child: Text('Highest Wage')),
        DropdownMenuItem(value: 'lowest_wage', child: Text('Lowest Wage')),
      ],
      onChanged: (value) {
        if (value != null) {
          jobsProvider.setSortBy(value);
        }
      },
    );
  }

  Widget _buildFilterSection() {
    final jobsProvider = context.watch<JobsProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Filter
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
              ...JobsProvider.jobStatuses.map((status) {
                final isSelected = jobsProvider.selectedStatus == status;
                return FilterChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (selected) {
                    jobsProvider.setStatusFilter(selected ? status : null);
                  },
                  selectedColor: kPrimaryColor.withValues(alpha: 0.3),
                  checkmarkColor: kPrimaryColor,
                );
              }),
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
                  value: jobsProvider.selectedCategory,
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
                    ...jobsProvider.categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    jobsProvider.setCategoryFilter(value);
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
                  value: jobsProvider.selectedBarangay,
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
                    jobsProvider.setBarangayFilter(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    final jobsProvider = context.watch<JobsProvider>();

    if (jobsProvider.isLoading && jobsProvider.filteredJobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobsProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(jobsProvider.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Trigger refresh
                jobsProvider.clearFilters();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (jobsProvider.filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No jobs found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or post a new job',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Jobs are streamed, so this is just a visual feedback
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80), // Space for FAB
        itemCount: jobsProvider.filteredJobs.length,
        itemBuilder: (context, index) {
          final job = jobsProvider.filteredJobs[index];
          return _buildJobCard(job);
        },
      ),
    );
  }

  Widget _buildJobCard(JobModel job) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToJobDetail(context, job),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Title + Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(job.status),
                ],
              ),
              const SizedBox(height: 8),
              // Category chip
              Chip(
                label: Text(job.category),
                backgroundColor: kAccentColor.withValues(alpha: 0.3),
                labelStyle: const TextStyle(fontSize: 12),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(height: 8),
              // Description preview
              Text(
                job.description,
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Footer: Wage, Barangay, Date
              Row(
                children: [
                  // Wage
                  Icon(Icons.payments, size: 16, color: kPrimaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '₱${job.wage.toStringAsFixed(0)}',
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
                      job.barangay,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Date
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(job.createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              // Applicants count (if any)
              if (job.applicants.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.blue.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${job.applicants.length} applicant${job.applicants.length > 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.blue.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ],
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
      case 'Open':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case 'In Progress':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        break;
      case 'Completed':
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToJobDetail(BuildContext context, JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailScreen(job: job),
      ),
    );
  }

  void _navigateToCreateJob(BuildContext context) {
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to post a job')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateJobScreen(),
      ),
    );
  }
}
