import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/payment_models.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/common/app_button.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  String _confirmationSubtitle(BookingModel booking) {
    if (booking.isPaid) return 'Your appointment is confirmed and paid.';
    if (booking.paymentMethod == PaymentMethod.cash) {
      return 'Your appointment is confirmed. Payment will be collected at the salon.';
    }
    return 'Your appointment is scheduled. Complete payment from My Bookings if it is still pending.';
  }

  String _confirmationTitle(BookingModel booking) {
    if (booking.isPaid || booking.paymentMethod == PaymentMethod.cash) {
      return AppStrings.bookingConfirmed;
    }
    return 'Booking Scheduled';
  }

  void _goToBookingsTab(BuildContext context) {
    context.read<BookingProvider>().loadBookings(forceRefresh: true);
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.main,
      (_) => false,
      arguments: 1,
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.main,
      (_) => false,
      arguments: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = ModalRoute.of(context)!.settings.arguments as BookingModel;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 68,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _confirmationTitle(booking),
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.textPrimaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _confirmationSubtitle(booking),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorderOf(context)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: AppIcons.icon(
                          booking.iconName,
                          size: 34,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      booking.serviceName,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.partnerDisplayName,
                      style: AppTextStyles.bodyMedium.copyWith(
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
                    const Divider(height: 28),
                    _DetailRow(
                      Icons.tag_rounded,
                      'Booking ID',
                      booking.bookingCode,
                    ),
                    _DetailRow(
                      Icons.calendar_today_rounded,
                      'Date',
                      Formatters.date(booking.scheduledAt),
                    ),
                    _DetailRow(
                      Icons.schedule_rounded,
                      'Time',
                      Formatters.time(booking.scheduledAt),
                    ),
                    _DetailRow(
                      Icons.location_on_outlined,
                      'Address',
                      booking.addressLine,
                    ),
                    _DetailRow(
                      Icons.payments_outlined,
                      'Amount',
                      Formatters.currency(booking.amount),
                    ),
                    _DetailRow(
                      Icons.account_balance_wallet_outlined,
                      'Payment',
                      booking.paymentMethodLabel,
                    ),
                    _DetailRow(
                      Icons.receipt_long_outlined,
                      'Status',
                      booking.paymentStatusLabel,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'View Booking',
                onPressed: () => _goToBookingsTab(context),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Back to Home',
                isOutlined: true,
                onPressed: () => _goToHome(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
