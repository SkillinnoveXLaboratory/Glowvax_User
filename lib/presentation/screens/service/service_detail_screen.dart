import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/service_model.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/rating_stars.dart';
import '../../widgets/reviews/service_reviews_section.dart';
import '../../../core/utils/app_icons.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  String? _partnerId;
  bool _favoritesRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_favoritesRequested) return;
    final service = ModalRoute.of(context)!.settings.arguments as ServiceModel;
    _partnerId = service.partnerId ?? service.id;
    _favoritesRequested = true;
    context.read<FavoritesProvider>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final service = ModalRoute.of(context)!.settings.arguments as ServiceModel;
    final partnerId = _partnerId ?? service.partnerId ?? service.id;
    final favorites = context.watch<FavoritesProvider>();
    final isFav = favorites.isFavorited(partnerId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppColors.error : Colors.white,
                ),
                onPressed: () => favorites.toggleFavorite(partnerId),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: AppIcons.icon(
                    service.iconName,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: AppTextStyles.displayLarge.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RatingStars(rating: service.rating),
                      const SizedBox(width: 8),
                      Text(
                        '${service.reviewCount} reviews',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    service.description,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Select Package', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 12),
                  ...service.packages.map(
                    (pkg) => _PackageCard(
                      package: pkg,
                      onBook: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.bookingFlow,
                          arguments: {'service': service, 'package': pkg},
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  ServiceReviewsSection(service: service, partnerId: partnerId),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final ServicePackageModel package;
  final VoidCallback onBook;

  const _PackageCard({required this.package, required this.onBook});

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
            Text(
              package.name,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  Formatters.currency(package.price),
                  style: AppTextStyles.price,
                ),
                const Spacer(),
                Text(
                  '${package.durationMinutes} min',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(label: AppStrings.bookNow, onPressed: onBook),
          ],
        ),
      ),
    );
  }
}
