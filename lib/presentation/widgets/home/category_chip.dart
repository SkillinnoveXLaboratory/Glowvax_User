import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/category_model.dart';

class CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryChip({super.key, required this.category, required this.onTap});

  IconData get _icon {
    switch (category.type) {
      case ServiceCategoryType.parlour:
        return Icons.content_cut_rounded;
      case ServiceCategoryType.spa:
        return Icons.spa_rounded;
      case ServiceCategoryType.tattoo:
        return Icons.brush_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorderOf(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(_icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 9),
              Text(
                category.name,
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 11,
                  color: AppColors.textPrimaryOf(context),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
