import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_icons.dart';

class HomeMembershipBanner extends StatelessWidget {
  final VoidCallback onTap;

  const HomeMembershipBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
            boxShadow: AppDecorations.buttonShadow(context),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  AppIcons.membership,
                  size: 28,
                  color: AppColors.textOnGold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Glowvax Membership',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textOnGold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unlock premium perks and save up to 20% on bookings',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnGold.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textOnGold.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
