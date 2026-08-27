import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/review_repository.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/rating_stars.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 5;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit(String bookingId, String serviceName) async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your review'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<ReviewRepository>().addReview(
        ReviewModel(
          id: '',
          userId: '',
          userName: '',
          serviceId: '',
          serviceName: serviceName,
          bookingId: bookingId,
          rating: _rating,
          comment: comment,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException
            ? e.message
            : 'Failed to submit review';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final bookingId = args['bookingId'] as String;
    final serviceName = args['serviceName'] as String? ?? 'Service';
    final partnerName = args['partnerName'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Write Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serviceName, style: AppTextStyles.headlineMedium),
            if (partnerName != null && partnerName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(partnerName, style: AppTextStyles.bodyMedium),
            ],
            const SizedBox(height: 8),
            Text('How was your experience?', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: List.generate(5, (i) {
                return IconButton(
                  onPressed: () => setState(() => _rating = i + 1.0),
                  icon: Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.gold,
                    size: 36,
                  ),
                );
              }),
            ),
            RatingStars(rating: _rating, size: 16),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your review',
                hintText: 'Share your experience...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Submit Review',
              isLoading: _isLoading,
              onPressed: () => _submit(bookingId, serviceName),
            ),
          ],
        ),
      ),
    );
  }
}
