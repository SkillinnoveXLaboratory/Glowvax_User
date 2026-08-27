import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/common/app_button.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myBookings),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: booking.isLoading && !booking.hasLoaded && booking.bookings.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : booking.bookingError != null && booking.bookings.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      booking.bookingError!,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Retry',
                      onPressed: () => booking.loadBookings(forceRefresh: true),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => booking.loadBookings(forceRefresh: true),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BookingList(
                    bookings: booking.upcomingBookings,
                    emptyTitle: 'No upcoming bookings',
                    emptySubtitle: 'Book a service to see it here.',
                  ),
                  _BookingList(
                    bookings: booking.pastBookings,
                    emptyTitle: 'No past bookings',
                    emptySubtitle:
                        'Completed and cancelled bookings will appear here.',
                  ),
                ],
              ),
            ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final String emptyTitle;
  final String emptySubtitle;

  const _BookingList({
    required this.bookings,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyStateWidget(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: Icons.calendar_today_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) => _BookingCard(booking: bookings[index]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.upcoming:
        return AppColors.info;
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.error;
      case BookingStatus.inProgress:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderOf(context)),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.bookingDetail,
          arguments: booking.id,
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: AppIcons.icon(
                        booking.iconName,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceName,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.partnerDisplayName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.packageName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      booking.statusDisplayLabel,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetaPill(
                    icon: Icons.tag_rounded,
                    label: 'Booking ID',
                    value: booking.bookingCode,
                  ),
                  _MetaPill(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: Formatters.date(booking.scheduledAt),
                  ),
                  _MetaPill(
                    icon: Icons.schedule_rounded,
                    label: 'Time',
                    value: Formatters.time(booking.scheduledAt),
                  ),
                  _MetaPill(
                    icon: Icons.payments_outlined,
                    label: 'Amount',
                    value: Formatters.currency(booking.amount),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoRow(Icons.location_on_outlined, booking.addressLine),
              if (booking.status == BookingStatus.upcoming) ...[
                const SizedBox(height: 16),
                AppButton(
                  label: 'View Booking',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.bookingDetail,
                    arguments: booking.id,
                  ),
                ),
              ],
              if (booking.canReview) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'Write a Review',
                  isOutlined: true,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.writeReview,
                    arguments: {
                      'bookingId': booking.id,
                      'serviceName': booking.serviceName,
                      'partnerName': booking.partnerDisplayName,
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondaryOf(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ),
      ],
    );
  }
}
