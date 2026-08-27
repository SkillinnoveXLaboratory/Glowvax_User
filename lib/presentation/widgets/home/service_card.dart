import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/service_model.dart';
import '../common/premium_card.dart';
import '../common/rating_stars.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const ServiceCard({super.key, required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardWidth = Responsive.serviceCardWidth(context);

    return PremiumCard(
      onTap: onTap,
      margin: const EdgeInsets.only(right: 14),
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 128,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradientOf(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDecorations.cardRadius),
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorderOf(context)),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -16,
                    top: -12,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Center(
                    child: AppIcons.icon(
                      service.iconName,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimaryOf(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RatingStars(rating: service.rating, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${service.reviewCount} reviews',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryOf(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    service.category.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'From ${Formatters.currency(service.startingPrice)}',
                          style: AppTextStyles.price.copyWith(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${service.minDuration} min',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceListTile extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const ServiceListTile({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 6,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradientOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorderOf(context)),
            ),
            child: Center(
              child: AppIcons.icon(
                service.iconName,
                size: 28,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    RatingStars(rating: service.rating, size: 14),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        service.category.label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'From ${Formatters.currency(service.startingPrice)} - ${service.minDuration} min',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
