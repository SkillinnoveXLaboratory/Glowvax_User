import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/time_slot_model.dart';

class BannerCarousel extends StatefulWidget {
  final List<OfferBannerModel> banners;

  const BannerCarousel({super.key, required this.banners});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);
    final banners = widget.banners.isEmpty
        ? [_fallbackBanner()]
        : widget.banners;

    return Column(
      children: [
        SizedBox(
          height: 178,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return AnimatedPadding(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.only(
                  left: index == 0 ? hPad : 8,
                  right: 8,
                  top: index == _currentPage ? 0 : 6,
                  bottom: index == _currentPage ? 0 : 6,
                ),
                child: Container(
                  decoration: AppDecorations.heroCard(context),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: AppColors.buttonGradient,
                        ),
                      ),
                      Positioned(
                        right: -24,
                        top: -28,
                        child: Container(
                          width: 136,
                          height: 136,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -22,
                        right: 8,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Own Your Glow',
                                    style: AppTextStyles.overline.copyWith(
                                      color: AppColors.goldLight,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    banner.title,
                                    style: AppTextStyles.headlineLarge.copyWith(
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    banner.subtitle,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: AppDecorations.goldBadge(
                                      context,
                                    ),
                                    child: Text(
                                      banner.discountText,
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.textOnGold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              child: AppIcons.icon(
                                banner.iconName,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            final active = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: active ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.textHintOf(context),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }

  OfferBannerModel _fallbackBanner() {
    return const OfferBannerModel(
      id: 'fallback',
      title: 'Book Salon and Beauty Services Near You',
      subtitle: 'Trusted professionals, flexible timing, and secure payments.',
      discountText: 'Book Now',
      iconName: 'spa',
    );
  }
}
