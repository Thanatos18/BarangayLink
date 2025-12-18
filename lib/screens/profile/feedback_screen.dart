import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/feedback.dart';
import '../../providers/feedback_provider.dart';
import '../../widgets/custom_app_bar.dart';

class FeedbackScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const FeedbackScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FeedbackProvider>(
        context,
        listen: false,
      ).startListening(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedbackProvider = Provider.of<FeedbackProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(title: '${widget.userName}\'s Reviews'),
      body: Column(
        children: [
          // Rating Summary Header
          _buildRatingSummary(feedbackProvider),

          // Sort Options
          _buildSortOptions(feedbackProvider),

          // Feedback List
          Expanded(child: _buildFeedbackList(feedbackProvider)),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(FeedbackProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Average Rating
          Column(
            children: [
              Text(
                provider.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isFullStar =
                      starIndex <= provider.averageRating.floor();
                  final isHalfStar =
                      starIndex == provider.averageRating.floor() + 1 &&
                      provider.averageRating % 1 >= 0.5;

                  return Icon(
                    isFullStar
                        ? Icons.star
                        : isHalfStar
                        ? Icons.star_half
                        : Icons.star_border,
                    color: kAccentColor,
                    size: 20,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Total Reviews
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.totalReviews} reviews',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRatingBar(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(FeedbackProvider provider) {
    if (provider.totalReviews == 0) {
      return const Text(
        'No reviews yet',
        style: TextStyle(color: Colors.white70),
      );
    }

    // Calculate rating distribution
    final distribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      distribution[i] = 0;
    }
    for (var feedback in provider.userFeedback) {
      distribution[feedback.rating] = (distribution[feedback.rating] ?? 0) + 1;
    }

    return Column(
      children: List.generate(5, (index) {
        final stars = 5 - index;
        final count = distribution[stars] ?? 0;
        final percentage = provider.totalReviews > 0
            ? count / provider.totalReviews
            : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$stars',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Icon(Icons.star, size: 12, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(kAccentColor),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSortOptions(FeedbackProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          _buildSortChip('Newest', 'newest', provider),
          const SizedBox(width: 8),
          _buildSortChip('Highest', 'highest', provider),
          const SizedBox(width: 8),
          _buildSortChip('Lowest', 'lowest', provider),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value, FeedbackProvider provider) {
    final isSelected = provider.sortBy == value;

    return GestureDetector(
      onTap: () => provider.setSortBy(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackList(FeedbackProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(provider.errorMessage!),
          ],
        ),
      );
    }

    final feedbackList = provider.userFeedback;

    if (feedbackList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: feedbackList.length,
      itemBuilder: (context, index) {
        return _buildFeedbackCard(feedbackList[index]);
      },
    );
  }

  Widget _buildFeedbackCard(FeedbackModel feedback) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Reviewer info + Rating
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  child: Text(
                    (feedback.reviewedByName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.reviewedByName ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(feedback.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Star Rating
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < feedback.rating ? Icons.star : Icons.star_border,
                      color: kAccentColor,
                      size: 18,
                    );
                  }),
                ),
              ],
            ),
            // Review Text
            if (feedback.review.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                feedback.review,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
            ],
            // Barangay Badge
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                feedback.barangay,
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
