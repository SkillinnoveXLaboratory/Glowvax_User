import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeHeader extends StatefulWidget {
  final String userName;
  final int unreadCount;
  final String selectedCity;
  final ValueChanged<String>? onCityChanged;
  final VoidCallback onNotificationsTap;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.unreadCount,
    this.selectedCity = AppConstants.defaultCity,
    this.onCityChanged,
    required this.onNotificationsTap,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  late String _currentCity;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _currentCity = widget.selectedCity;
  }

  void _showCitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textHintOf(
                            context,
                          ).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Your Location',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Discover beauty and wellness professionals in your city',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      tileColor: AppColors.primary.withValues(alpha: 0.08),
                      leading: _isLocating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.primary,
                            ),
                      title: Text(
                        'Detect Current Location',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      subtitle: Text(
                        'Use GPS to estimate your city',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                      onTap: () async {
                        setModalState(() => _isLocating = true);
                        final pos = await LocationService.getCurrentPosition();
                        setModalState(() => _isLocating = false);
                        if (pos != null) {
                          final city = LocationService.estimateCityFromCoords(
                            pos.latitude,
                            pos.longitude,
                          );
                          setState(() => _currentCity = city);
                          widget.onCityChanged?.call(city);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } else if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Location permission denied or unavailable. Select a city manually.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Available Cities',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: LocationService.supportedCities.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: AppColors.cardBorderOf(context),
                        ),
                        itemBuilder: (context, i) {
                          final city = LocationService.supportedCities[i];
                          final isSelected =
                              city.toLowerCase() == _currentCity.toLowerCase();
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            leading: Icon(
                              Icons.location_city_rounded,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondaryOf(context),
                            ),
                            title: Text(
                              city,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimaryOf(context),
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  )
                                : null,
                            onTap: () {
                              setState(() => _currentCity = city);
                              widget.onCityChanged?.call(city);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.userName.split(' ').first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $firstName',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimaryOf(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Your next glow-up is one tap away',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showCitySelector,
                  borderRadius: BorderRadius.circular(24),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.cardBorderOf(context),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentCity,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onNotificationsTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorderOf(context)),
              ),
              child: Badge(
                isLabelVisible: widget.unreadCount > 0,
                backgroundColor: AppColors.primary,
                label: Text(
                  '${widget.unreadCount}',
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 9,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
