import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/transaction.dart';
import '../../providers/feedback_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';

class SubmitFeedbackScreen extends StatefulWidget {
  final TransactionModel transaction;

  const SubmitFeedbackScreen({super.key, required this.transaction});

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  static const int _maxReviewLength = 500;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Leave Feedback'),
        body: Center(child: Text('Please log in')),
      );
    }

    // Determine who is being reviewed
    final isInitiator = widget.transaction.initiatedBy == currentUser.uid;
    final reviewedUserId = isInitiator
        ? widget.transaction.targetUser
        : widget.transaction.initiatedBy;
    final reviewedUserName = isInitiator
        ? widget.transaction.targetUserName
        : widget.transaction.initiatedByName;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Leave Feedback'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Info Card
            _buildTransactionCard(),
            const SizedBox(height: 24),

            // Rating Section
            _buildRatingSection(reviewedUserName ?? 'this user'),
            const SizedBox(height: 24),

            // Review Section
            _buildReviewSection(),
            const SizedBox(height: 32),

            // Submit Button
            _buildSubmitButton(
              context,
              currentUser.uid,
              currentUser.name,
              reviewedUserId,
              reviewedUserName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.transaction.typeLabel,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  Text(
                    widget.transaction.relatedName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How was your experience with $userName?',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        // Star Rating
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNumber = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = starNumber;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    starNumber <= _selectedRating
                        ? Icons.star
                        : Icons.star_border,
                    size: 48,
                    color: starNumber <= _selectedRating
                        ? kAccentColor
                        : Colors.grey[400],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        // Rating Label
        Center(
          child: Text(
            _getRatingLabel(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _getRatingColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Write a review (optional)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          maxLines: 5,
          maxLength: _maxReviewLength,
          decoration: InputDecoration(
            hintText: 'Share your experience...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            counterText: '${_reviewController.text.length}/$_maxReviewLength',
          ),
          onChanged: (value) {
            setState(() {}); // Update character count
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    String reviewerId,
    String reviewerName,
    String reviewedUserId,
    String? reviewedUserName,
  ) {
    final isValid = _selectedRating > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid && !_isSubmitting
            ? () => _submitFeedback(
                context,
                reviewerId,
                reviewerName,
                reviewedUserId,
                reviewedUserName,
              )
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Submit Feedback',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitFeedback(
    BuildContext context,
    String reviewerId,
    String reviewerName,
    String reviewedUserId,
    String? reviewedUserName,
  ) async {
    if (_selectedRating == 0) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final feedbackProvider = Provider.of<FeedbackProvider>(
        context,
        listen: false,
      );

      final success = await feedbackProvider.submitFeedback(
        rating: _selectedRating,
        review: _reviewController.text.trim(),
        transactionId: widget.transaction.id,
        reviewedBy: reviewerId,
        reviewedByName: reviewerName,
        reviewedUser: reviewedUserId,
        reviewedUserName: reviewedUserName,
        barangay: widget.transaction.barangay,
      );

      if (mounted) {
        if (success) {
          // Show success dialog
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Feedback Submitted!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thank you for your feedback.',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to detail
                      },
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                feedbackProvider.errorMessage ?? 'Failed to submit feedback',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getRatingLabel() {
    switch (_selectedRating) {
      case 1:
        return 'Very Poor 😞';
      case 2:
        return 'Poor 😕';
      case 3:
        return 'Average 😐';
      case 4:
        return 'Good 😊';
      case 5:
        return 'Excellent 🎉';
      default:
        return 'Tap a star to rate';
    }
  }

  Color _getRatingColor() {
    switch (_selectedRating) {
      case 1:
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
