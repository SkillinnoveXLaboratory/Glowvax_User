import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showValue;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.rating, size: size),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.titleMedium.copyWith(fontSize: size - 2),
          ),
        ],
      ],
    );
  }
}

class InteractiveRatingStars extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;
  final double size;

  const InteractiveRatingStars({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return GestureDetector(
          onTap: () => onChanged(starValue),
          child: Icon(
            starValue <= rating
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: AppColors.rating,
            size: size,
          ),
        );
      }),
    );
  }
}
