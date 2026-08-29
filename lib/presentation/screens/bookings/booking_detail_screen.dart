import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/payment/razorpay_payment_service.dart';
import '../../../core/pdf/booking_invoice_actions.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/payment_models.dart';
import '../../../data/models/tip_record_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/common/app_button.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bookingId = ModalRoute.of(context)!.settings.arguments as String;
    context.read<BookingProvider>().loadBookingDetail(bookingId);
  }

  Future<void> _showInvoice(String bookingId) async {
    final invoice = await context.read<BookingProvider>().getInvoice(bookingId);
    if (!mounted) return;
    await openBookingInvoicePdf(context, invoice);
  }

  Future<void> _reschedule(BookingModel booking) async {
    final date = await showDatePicker(
      context: context,
      initialDate: booking.scheduledAt.add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    await context.read<BookingProvider>().rescheduleBooking(
      booking.id,
      date,
      '${booking.scheduledAt.hour.toString().padLeft(2, '0')}:${booking.scheduledAt.minute.toString().padLeft(2, '0')}',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reschedule request sent'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
          booking.isPaid
              ? 'If you cancel, any approved refund will be credited to your Glowvax wallet.'
              : 'Are you sure you want to cancel this booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await context.read<BookingProvider>().cancelBooking(booking.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showTipSheet(BookingModel booking) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TipSheet(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final booking = provider.selectedBooking;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: provider.isLoading && booking == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : booking == null
          ? Center(
              child: Text(
                'Booking not found',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(booking: booking),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Schedule',
                    children: [
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
                      if (booking.staffDisplayName != null)
                        _DetailRow(
                          Icons.badge_outlined,
                          'Staff',
                          booking.staffDisplayName!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Payment',
                    children: [
                      _DetailRow(
                        Icons.payments_outlined,
                        'Amount',
                        Formatters.currency(booking.amount),
                      ),
                      _DetailRow(
                        Icons.account_balance_wallet_outlined,
                        'Method',
                        booking.paymentMethodLabel,
                      ),
                      _DetailRow(
                        Icons.receipt_long_outlined,
                        'Status',
                        booking.paymentStatusLabel,
                      ),
                      if (booking.tipAmount > 0)
                        _DetailRow(
                          Icons.volunteer_activism_outlined,
                          'Tip',
                          Formatters.currency(booking.tipAmount),
                        ),
                    ],
                  ),
                  if (booking.status == BookingStatus.completed) ...[
                    const SizedBox(height: 16),
                    _PartnerTipsSection(
                      isLoading: provider.isLoadingPartnerTips,
                      tips: provider.partnerTips,
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (booking.status == BookingStatus.upcoming) ...[
                    if (!booking.isPaid &&
                        booking.paymentMethod != PaymentMethod.cash)
                      AppButton(
                        label: booking.paymentMethod == PaymentMethod.wallet
                            ? 'Pay with Wallet'
                            : 'Pay Now',
                        isLoading: provider.isLoading,
                        onPressed: () async {
                          final user = context.read<AuthProvider>().user;
                          final paid = await provider.payForBooking(
                            booking: booking,
                            razorpay: context.read<RazorpayPaymentService>(),
                            contact: user?.phone ?? '',
                            email: user?.email,
                          );
                          if (!context.mounted) return;
                          if (paid != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment successful'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else if (provider.bookingError != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.bookingError!),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                      ),
                    if (!booking.isPaid &&
                        booking.paymentMethod != PaymentMethod.cash)
                      const SizedBox(height: 12),
                    AppButton(
                      label: 'Reschedule',
                      isOutlined: true,
                      onPressed: () => _reschedule(booking),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Cancel Booking',
                      isOutlined: true,
                      onPressed: () => _cancelBooking(booking),
                    ),
                  ],
                  if (booking.status == BookingStatus.completed) ...[
                    if (booking.canAddTip) ...[
                      AppButton(
                        label: 'Add Tip',
                        onPressed: () => _showTipSheet(booking),
                      ),
                      const SizedBox(height: 12),
                    ],
                    AppButton(
                      label: 'Write a Review',
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
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Request Refund',
                      isOutlined: true,
                      onPressed: () async {
                        await provider.requestRefund(
                          booking.id,
                          'User requested refund',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Refund request submitted'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (booking.isPaid ||
                      booking.paymentMethod == PaymentMethod.cash)
                    AppButton(
                      label: 'View Invoice',
                      isOutlined: true,
                      onPressed: () => _showInvoice(booking.id),
                    ),
                ],
              ),
            ),
    );
  }
}

class _TipSheet extends StatefulWidget {
  final BookingModel booking;

  const _TipSheet({required this.booking});

  @override
  State<_TipSheet> createState() => _TipSheetState();
}

class _TipSheetState extends State<_TipSheet> {
  static const List<double> _quickAmounts = [20, 50, 100];
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  double? _selectedAmount = 50;
  bool _isCustom = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? get _resolvedAmount {
    if (_isCustom) {
      return double.tryParse(_customAmountController.text.trim());
    }
    return _selectedAmount;
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final wallet = context.watch<WalletProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final amount = _resolvedAmount;
    final canSubmit =
        amount != null && amount > 0 && !bookingProvider.isAddingTip;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Material(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorderOf(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Add Tip',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Thank ${widget.booking.partnerDisplayName} for the completed service.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final quick in _quickAmounts)
                      _TipAmountChip(
                        label: '\u20B9${quick.toStringAsFixed(0)}',
                        selected: !_isCustom && _selectedAmount == quick,
                        onTap: () => setState(() {
                          _isCustom = false;
                          _selectedAmount = quick;
                        }),
                      ),
                    _TipAmountChip(
                      label: 'Custom',
                      selected: _isCustom,
                      onTap: () => setState(() => _isCustom = true),
                    ),
                  ],
                ),
                if (_isCustom) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _customAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimaryOf(context),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Custom tip amount',
                      prefixText: '\u20B9 ',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  minLines: 2,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimaryOf(context),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Tip note',
                    hintText: 'Optional note for the salon',
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedOf(context),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment method',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Glowvax Wallet',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Available balance: ${Formatters.currency(wallet.balance)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (bookingProvider.bookingError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    bookingProvider.bookingError!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                AppButton(
                  label: amount != null
                      ? 'Confirm ${Formatters.currency(amount)} Tip'
                      : 'Confirm Tip',
                  isLoading: bookingProvider.isAddingTip,
                  onPressed: canSubmit
                      ? () async {
                          final success = await bookingProvider.addTip(
                            booking: widget.booking,
                            amount: amount,
                            note: _noteController.text,
                          );
                          if (!context.mounted) return;
                          if (success) {
                            await context.read<WalletProvider>().loadWallet();
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tip added successfully'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PartnerTipsSection extends StatelessWidget {
  final bool isLoading;
  final List<TipRecordModel> tips;

  const _PartnerTipsSection({required this.isLoading, required this.tips});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Salon Tips',
      children: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (tips.isEmpty)
          Text(
            'No tip records available yet for this salon.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          )
        else
          ...tips
              .take(3)
              .map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Formatters.currency(tip.amount),
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tip.description,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.date(tip.createdAt),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }
}

class _TipAmountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TipAmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.cardBorderOf(context),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: selected
                ? AppColors.primary
                : AppColors.textPrimaryOf(context),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final BookingModel booking;

  const _HeroCard({required this.booking});

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
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradientOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: AppIcons.icon(
                    booking.iconName,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.statusDisplayLabel,
                  style: AppTextStyles.labelMedium.copyWith(color: statusColor),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Booking ID ${booking.bookingCode}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 86,
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
