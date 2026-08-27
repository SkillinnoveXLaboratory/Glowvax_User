import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/category_model.dart';
import 'home_section_header.dart';

class HomeServicePreviewSection extends StatelessWidget {
  final List<CategoryModel> categories;
  final void Function(CategoryModel category) onCategoryTap;

  const HomeServicePreviewSection({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  IconData _iconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('hair') ||
        lower.contains('cut') ||
        lower.contains('barber')) {
      return Icons.content_cut_rounded;
    }
    if (lower.contains('skin') || lower.contains('facial')) {
      return Icons.face_retouching_natural_rounded;
    }
    if (lower.contains('nail') ||
        lower.contains('pedi') ||
        lower.contains('mani')) {
      return Icons.pan_tool_outlined;
    }
    if (lower.contains('spa') || lower.contains('massage')) {
      return Icons.spa_rounded;
    }
    if (lower.contains('makeup') || lower.contains('bridal')) {
      return Icons.auto_fix_high_rounded;
    }
    if (lower.contains('wax')) {
      return Icons.cleaning_services_rounded;
    }
    if (lower.contains('tattoo') || lower.contains('art')) {
      return Icons.brush_rounded;
    }
    if (lower.contains('grooming')) {
      return Icons.self_improvement_rounded;
    }
    if (lower.contains('wellness') || lower.contains('body')) {
      return Icons.favorite_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final hPad = Responsive.horizontalPadding(context);
    final displayCategories = categories.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Book by Category',
          subtitle: 'Find trusted beauty and wellness services near you',
        ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              final category = displayCategories[index];
              return _CategoryTile(
                category: category,
                icon: _iconForCategory(category.name),
                onTap: () => onCategoryTap(category),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final CategoryModel category;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.surfaceElevatedOf(context)
                : AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pressed
                  ? AppColors.primary
                  : AppColors.cardBorderOf(context),
              width: _pressed ? 1.4 : 1,
            ),
            boxShadow: _pressed
                ? AppDecorations.glowShadow(context)
                : AppDecorations.cardShadow(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.16),
                      AppColors.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  widget.category.name,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.textPrimaryOf(context),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
