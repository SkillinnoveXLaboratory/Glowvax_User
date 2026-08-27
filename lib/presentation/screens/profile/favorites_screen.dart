import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/repositories/service_repository.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/common/rating_stars.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String? _loadingPartnerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadFavorites(forceRefresh: true);
    });
  }

  Future<void> _openFavorite(String partnerId) async {
    setState(() => _loadingPartnerId = partnerId);
    try {
      final service = await context
          .read<ServiceRepository>()
          .getServiceForPartner(partnerId);
      if (!mounted) return;
      if (service != null) {
        await Navigator.pushNamed(
          context,
          AppRoutes.serviceDetail,
          arguments: service,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load service details'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPartnerId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: provider.isLoading && !provider.hasLoaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : provider.error != null && provider.favorites.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      provider.error!,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          provider.loadFavorites(forceRefresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : provider.favorites.isEmpty
          ? const Center(child: Text('No favorites yet'))
          : RefreshIndicator(
              onRefresh: () => provider.loadFavorites(forceRefresh: true),
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.favorites.length,
                itemBuilder: (context, index) {
                  final fav = provider.favorites[index];
                  final isLoading = _loadingPartnerId == fav.partnerId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: isLoading
                          ? null
                          : () => _openFavorite(fav.partnerId),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.spa_outlined,
                                color: AppColors.primary,
                              ),
                      ),
                      title: Text(
                        fav.businessName,
                        style: AppTextStyles.titleLarge,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (fav.city != null)
                            Text(fav.city!, style: AppTextStyles.bodySmall),
                          RatingStars(rating: fav.rating, size: 14),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textHint,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.favorite,
                              color: AppColors.error,
                            ),
                            onPressed: () =>
                                provider.toggleFavorite(fav.partnerId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
