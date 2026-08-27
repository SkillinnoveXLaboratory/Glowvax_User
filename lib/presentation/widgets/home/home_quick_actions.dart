import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeQuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const HomeQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class HomeQuickActions extends StatelessWidget {
  final List<HomeQuickAction> actions;

  const HomeQuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  decoration: AppDecorations.premiumCard(context),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          action.icon,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        action.label,
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
            ),
          ),
        );
      }).toList(),
    );
  }
}
