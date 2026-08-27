import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/review_model.dart';
import '../../../data/models/service_model.dart';
import '../../../data/repositories/review_repository.dart';
import '../common/rating_stars.dart';
import 'review_card.dart';

class ServiceReviewsSection extends StatefulWidget {
  final ServiceModel service;
  final String partnerId;

  const ServiceReviewsSection({
    super.key,
    required this.service,
    required this.partnerId,
  });

  @override
  State<ServiceReviewsSection> createState() => _ServiceReviewsSectionState();
}

class _ServiceReviewsSectionState extends State<ServiceReviewsSection> {
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final all = await context.read<ReviewRepository>().getReviews(
        partnerId: widget.partnerId,
      );
      final filtered = all.where(_matchesService).toList();
      if (!mounted) return;
      setState(() {
        _reviews = filtered;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  bool _matchesService(ReviewModel review) {
    if (review.serviceId.isNotEmpty) {
      return review.serviceId == widget.service.id;
    }
    if (review.serviceName.isNotEmpty) {
      return review.serviceName.toLowerCase() ==
          widget.service.name.toLowerCase();
    }
    return false;
  }

  double get _averageRating {
    if (_reviews.isEmpty) return widget.service.rating;
    return _reviews.map((r) => r.rating).reduce((a, b) => a + b) /
        _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Customer Reviews', style: AppTextStyles.headlineMedium),
            const Spacer(),
            if (!_isLoading && _reviews.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.reviews,
                  arguments: widget.partnerId,
                ),
                child: Text('See all (${_reviews.length})'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(color: AppColors.cardBorderOf(context)),
            ),
            child: Column(
              children: [
                Text(
                  _error!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: _loadReviews, child: const Text('Retry')),
              ],
            ),
          )
        else if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(color: AppColors.cardBorderOf(context)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 40,
                  color: AppColors.textHintOf(context),
                ),
                const SizedBox(height: 8),
                Text(
                  'No reviews for ${widget.service.name} yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          )
        else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(color: AppColors.cardBorderOf(context)),
            ),
            child: Row(
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 36,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RatingStars(rating: _averageRating, size: 18),
                      const SizedBox(height: 4),
                      Text(
                        '${_reviews.length} review${_reviews.length == 1 ? '' : 's'} for ${widget.service.name}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._reviews
              .take(3)
              .map(
                (review) => ReviewCard(
                  review: review,
                  showServiceName: true,
                  showPartnerName: false,
                ),
              ),
          if (_reviews.length > 3) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.reviews,
                  arguments: widget.partnerId,
                ),
                child: Text('View all ${_reviews.length} reviews'),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
