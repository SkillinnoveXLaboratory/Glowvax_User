import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/home/banner_carousel.dart';
import '../../widgets/home/category_chip.dart';
import '../../widgets/home/service_card.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/home_search_bar.dart';
import '../../widgets/home/home_quick_actions.dart';
import '../../widgets/home/home_service_preview_section.dart';
import '../../widgets/home/home_section_header.dart';
import '../../widgets/home/home_trust_strip.dart';
import '../../widgets/home/home_membership_banner.dart';
import '../../widgets/common/app_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeProvider>().loadHomeData();
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  String _selectedCity = AppConstants.defaultCity;

  void _openSearch([String? query]) {
    Navigator.pushNamed(context, AppRoutes.search, arguments: query);
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final auth = context.watch<AuthProvider>();
    final notifications = context.watch<NotificationProvider>();
    final hPad = Responsive.horizontalPadding(context);
    final userName = auth.user?.name ?? 'Guest';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: home.isLoading && !home.hasContent
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceOf(context),
                onRefresh: () => home.loadHomeData(force: true),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HomeHeader(
                              userName: userName,
                              unreadCount: notifications.unreadCount,
                              selectedCity: _selectedCity,
                              onCityChanged: (city) =>
                                  setState(() => _selectedCity = city),
                              onNotificationsTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.notifications,
                              ),
                            ),
                            const SizedBox(height: 18),
                            HomeSearchBar(onTap: () => _openSearch()),
                            const SizedBox(height: 18),
                            HomeQuickActions(
                              actions: [
                                HomeQuickAction(
                                  label: 'Book Now',
                                  icon: Icons.calendar_month_rounded,
                                  onTap: () => _openSearch(),
                                ),
                                HomeQuickAction(
                                  label: 'Bookings',
                                  icon: Icons.event_note_rounded,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.bookings,
                                  ),
                                ),
                                HomeQuickAction(
                                  label: 'Wallet',
                                  icon: Icons.account_balance_wallet_outlined,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.wallet,
                                  ),
                                ),
                                HomeQuickAction(
                                  label: 'Favorites',
                                  icon: Icons.favorite_border_rounded,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.favorites,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          if (home.banners.isNotEmpty) ...[
                            HomeSectionHeader(
                              title: AppStrings.offers,
                              subtitle: 'Exclusive deals for you',
                            ),
                            const SizedBox(height: 12),
                            BannerCarousel(banners: home.banners),
                            const SizedBox(height: 8),
                          ],
                          HomeServicePreviewSection(
                            categories: home.categories,
                            onCategoryTap: (cat) => Navigator.pushNamed(
                              context,
                              AppRoutes.categoryServices,
                              arguments: cat,
                            ),
                          ),
                          if (home.categories.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            HomeSectionHeader(
                              title: 'Trending Categories',
                              actionLabel: 'See all',
                              onAction: () => _openSearch(),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 96,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: hPad),
                                itemCount: home.categories.length,
                                itemBuilder: (context, index) => CategoryChip(
                                  category: home.categories[index],
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.categoryServices,
                                    arguments: home.categories[index],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          HomeSectionHeader(
                            title: AppStrings.popularServices,
                            subtitle: 'Most booked near you',
                            actionLabel: home.featuredServices.isNotEmpty
                                ? 'See all'
                                : null,
                            onAction: home.featuredServices.isNotEmpty
                                ? () => _openSearch('popular')
                                : null,
                          ),
                          const SizedBox(height: 14),
                          if (home.featuredServices.isEmpty)
                            _EmptyServicesHint(onExplore: () => _openSearch())
                          else
                            SizedBox(
                              height: 248,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: hPad),
                                itemCount: home.featuredServices.length,
                                itemBuilder: (context, index) => ServiceCard(
                                  service: home.featuredServices[index],
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.serviceDetail,
                                    arguments: home.featuredServices[index],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 28),
                          HomeSectionHeader(
                            title: AppStrings.topRated,
                            subtitle: 'Highest rated professionals',
                            actionLabel: home.topRatedServices.isNotEmpty
                                ? 'See all'
                                : null,
                            onAction: home.topRatedServices.isNotEmpty
                                ? () => _openSearch('top rated')
                                : null,
                          ),
                          const SizedBox(height: 14),
                          if (home.topRatedServices.isEmpty)
                            _EmptyServicesHint(onExplore: () => _openSearch())
                          else
                            SizedBox(
                              height: 248,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: hPad),
                                itemCount: home.topRatedServices.length,
                                itemBuilder: (context, index) => ServiceCard(
                                  service: home.topRatedServices[index],
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.serviceDetail,
                                    arguments: home.topRatedServices[index],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 28),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: const HomeTrustStrip(),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: HomeMembershipBanner(
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.membership,
                              ),
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EmptyServicesHint extends StatelessWidget {
  final VoidCallback onExplore;

  const _EmptyServicesHint({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cardBorderOf(context).withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.spa_outlined,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'No services found nearby',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching for salon, spa, or wellness',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Explore Services',
              onPressed: onExplore,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }
}
