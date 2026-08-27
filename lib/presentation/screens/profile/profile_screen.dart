import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/app_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _showThemeSheet(BuildContext context) async {
    final theme = context.read<ThemeProvider>();
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final currentMode = sheetContext.watch<ThemeProvider>().mode;
        final options = <MapEntry<ThemeMode, String>>[
          const MapEntry(ThemeMode.system, 'Match device'),
          const MapEntry(ThemeMode.light, 'Light mode'),
          const MapEntry(ThemeMode.dark, 'Dark mode'),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimaryOf(sheetContext),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how Glowvax should look across the app.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryOf(sheetContext),
                  ),
                ),
                const SizedBox(height: 18),
                ...options.map(
                  (option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option.value,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimaryOf(sheetContext),
                      ),
                    ),
                    trailing: Icon(
                      currentMode == option.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: currentMode == option.key
                          ? AppColors.primary
                          : AppColors.textHintOf(sheetContext),
                    ),
                    onTap: () => Navigator.pop(sheetContext, option.key),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await theme.setMode(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final secondaryText = AppColors.textSecondaryOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      (user?.name ?? 'U')[0].toUpperCase(),
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? 'Glow User',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.phone(user?.phone ?? ''),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  if ((user?.email ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      user!.email!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ProfileSection(
              children: [
                _ProfileTile(
                  icon: Icons.person_outline,
                  title: AppStrings.editProfile,
                  subtitle: 'Update your name and personal details',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                _ProfileTile(
                  icon: Icons.location_on_outlined,
                  title: AppStrings.myAddresses,
                  subtitle: 'Manage saved and default addresses',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.addresses),
                ),
                _ProfileTile(
                  icon: Icons.favorite_outline,
                  title: 'Favorites',
                  subtitle: 'View your liked salons and services',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.favorites),
                ),
                _ProfileTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: AppStrings.wallet,
                  subtitle: 'Check balance and transaction history',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.wallet),
                ),
              ],
            ),
            _ProfileSection(
              children: [
                _ProfileTile(
                  icon: Icons.card_membership_outlined,
                  title: AppStrings.membership,
                  subtitle: 'Explore plans, benefits, and billing',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.membership),
                ),
                _ProfileTile(
                  icon: Icons.notifications_outlined,
                  title: AppStrings.notifications,
                  subtitle: 'View alerts and booking updates',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.notifications),
                ),
                _ProfileTile(
                  icon: Icons.tune_outlined,
                  title: 'Notification Settings',
                  subtitle: 'Choose which updates you receive',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.notificationPreferences,
                  ),
                ),
                _ProfileTile(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Switch between light, dark, or system mode',
                  onTap: () => _showThemeSheet(context),
                ),
              ],
            ),
            _ProfileSection(
              children: [
                _ProfileTile(
                  icon: Icons.star_outline_rounded,
                  title: AppStrings.reviews,
                  subtitle: 'Read your posted reviews',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.reviews),
                ),
                _ProfileTile(
                  icon: Icons.rate_review_outlined,
                  title: 'Write a Review',
                  subtitle: 'Choose a completed booking and review it',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.reviews,
                    arguments: const {'mode': 'compose'},
                  ),
                ),
                if (user?.referralCode != null)
                  _ProfileTile(
                    icon: Icons.card_giftcard_outlined,
                    title: 'Referral Code',
                    subtitle: user!.referralCode!,
                    onTap: () {},
                  ),
                _ProfileTile(
                  icon: Icons.help_outline_rounded,
                  title: AppStrings.helpSupport,
                  subtitle: 'Contact support for booking or payment help',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.helpSupport),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.defaultPadding,
                20,
                AppConstants.defaultPadding,
                0,
              ),
              child: AppButton(
                label: AppStrings.logout,
                isOutlined: true,
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    context.read<FavoritesProvider>().clear();
                    context.read<BookingProvider>().reset();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.splash,
                      (_) => false,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Glowvax user account',
              style: AppTextStyles.bodySmall.copyWith(color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final List<Widget> children;

  const _ProfileSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderOf(context)),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.textPrimaryOf(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondaryOf(context),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.textHintOf(context)),
      onTap: onTap,
    );
  }
}
