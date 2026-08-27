import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeTrustStrip extends StatelessWidget {
  const HomeTrustStrip({super.key});

  static const _items = [
    (Icons.verified_rounded, 'Verified'),
    (Icons.lock_rounded, 'Secure Pay'),
    (Icons.flash_on_rounded, 'Instant Book'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: AppDecorations.premiumCard(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items.map((item) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.$1, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                item.$2,
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 11,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
