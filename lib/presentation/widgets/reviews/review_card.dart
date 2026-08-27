import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/review_model.dart';
import '../common/rating_stars.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool showServiceName;
  final bool showPartnerName;
  final bool showEdit;
  final bool showDelete;
  final bool showReport;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  const ReviewCard({
    super.key,
    required this.review,
    this.showServiceName = true,
    this.showPartnerName = false,
    this.showEdit = false,
    this.showDelete = false,
    this.showReport = false,
    this.onEdit,
    this.onDelete,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.cardBorderOf(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : 'U',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (showServiceName && review.serviceName.isNotEmpty)
                        _MetaChip(
                          icon: Icons.spa_outlined,
                          label: review.serviceName,
                          color: AppColors.primary,
                        ),
                      if (showPartnerName && review.partnerName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _MetaChip(
                          icon: Icons.storefront_outlined,
                          label: review.partnerName,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        Formatters.date(review.createdAt),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                RatingStars(rating: review.rating, size: 14),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            if (showEdit || showDelete || showReport) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showReport)
                    TextButton.icon(
                      onPressed: onReport,
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Report'),
                    ),
                  if (showEdit)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  if (showDelete)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
