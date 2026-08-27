import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/payment/razorpay_payment_service.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/address_model.dart';
import '../../../data/models/payment_models.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/time_slot_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/common/app_button.dart';

class BookingFlowScreen extends StatefulWidget {
  final ServiceModel service;
  final ServicePackageModel package;

  const BookingFlowScreen({
    super.key,
    required this.service,
    required this.package,
  });

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booking = context.read<BookingProvider>();
      booking.startBooking(widget.service, widget.package);
      booking.loadAddresses();
      context.read<WalletProvider>().loadWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${booking.selectedService?.name ?? 'Service'}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _StepIndicator(currentStep: _currentStep),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: _buildStepContent(booking),
            ),
          ),
          _buildBottomBar(booking),
        ],
      ),
    );
  }

  Widget _buildStepContent(BookingProvider booking) {
    switch (_currentStep) {
      case 0:
        return _DateStep(
          selectedDate: booking.selectedDate,
          onSelect: booking.selectDate,
        );
      case 1:
        return _TimeStep(
          slots: booking.timeSlots,
          selected: booking.selectedSlot,
          isLoading: booking.isLoadingSlots,
          onSelect: booking.selectSlot,
        );
      case 2:
        return _AddressStep(
          addresses: booking.addresses,
          selected: booking.selectedAddress,
          isLoading: booking.isLoadingAddresses,
          onSelect: booking.selectAddress,
          onAddAddress: () async {
            await Navigator.pushNamed(context, AppRoutes.addAddress);
            if (context.mounted) {
              await booking.loadAddresses();
            }
          },
          onRefresh: booking.loadAddresses,
        );
      case 3:
        return _SummaryStep(
          booking: booking,
          walletBalance: context.watch<WalletProvider>().balance,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar(BookingProvider booking) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        border: Border(top: BorderSide(color: AppColors.cardBorderOf(context))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: AppButton(
                  label: 'Back',
                  isOutlined: true,
                  onPressed: () => setState(() => _currentStep--),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppButton(
                label: _currentStep == 3
                    ? AppStrings.confirmBooking
                    : 'Continue',
                isLoading: booking.isLoading,
                onPressed: () => _onContinue(booking),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onContinue(BookingProvider booking) async {
    if (_currentStep == 0 && booking.selectedDate == null) {
      _showError('Please select a date');
      return;
    }
    if (_currentStep == 1 && booking.isLoadingSlots) {
      return;
    }
    if (_currentStep == 1 && booking.selectedSlot == null) {
      _showError(
        booking.timeSlots.isEmpty
            ? 'No time slots are available for this date. Please choose another date.'
            : 'Please select a time slot',
      );
      return;
    }
    if (_currentStep == 2 && booking.isLoadingAddresses) {
      return;
    }
    if (_currentStep == 2 && booking.selectedAddress == null) {
      _showError('Please select an address');
      return;
    }
    if (_currentStep == 3) {
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      final result = await booking.confirmBooking(
        razorpay: context.read<RazorpayPaymentService>(),
        contact: user?.phone ?? '',
        email: user?.email,
      );
      if (!mounted) return;
      if (result != null) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.bookingConfirmation,
          arguments: result,
        );
      } else if (booking.bookingError != null) {
        _showError(booking.bookingError!);
      }
      return;
    }
    setState(() {
      _currentStep++;
      if (_currentStep == 2) {
        booking.loadAddresses();
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['Date', 'Time', 'Address', 'Confirm'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        final isCurrent = index == currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.surfaceElevatedOf(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.cardBorderOf(context),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isActive
                                ? Colors.white
                                : AppColors.textHintOf(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index],
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isCurrent
                            ? AppColors.textPrimaryOf(context)
                            : AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: index < currentStep
                        ? AppColors.primary
                        : AppColors.cardBorderOf(context),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _DateStep extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelect;

  const _DateStep({required this.selectedDate, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);
    final dates = List.generate(
      14,
      (index) => startDate.add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          title: AppStrings.selectDate,
          subtitle: 'Choose an available date for your appointment.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: dates.map((date) {
            final isSelected =
                selectedDate != null &&
                date.year == selectedDate!.year &&
                date.month == selectedDate!.month &&
                date.day == selectedDate!.day;
            return InkWell(
              onTap: () => onSelect(date),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 78,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.cardBorderOf(context),
                    width: isSelected ? 1.6 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _weekday(date.weekday),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white70
                            : AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      _month(date.month),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white70
                            : AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _weekday(int day) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];

  String _month(int month) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _TimeStep extends StatelessWidget {
  final List<TimeSlotModel> slots;
  final TimeSlotModel? selected;
  final bool isLoading;
  final ValueChanged<TimeSlotModel> onSelect;

  const _TimeStep({
    required this.slots,
    required this.selected,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          title: AppStrings.selectTime,
          subtitle: 'Only live available slots are shown here.',
        ),
        const SizedBox(height: 18),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (slots.isEmpty)
          _MessageCard(
            icon: Icons.schedule_outlined,
            message:
                'No slots are available for this date. Please go back and choose another day.',
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: slots.map((slot) {
              final isSelected = selected?.id == slot.id;
              final disabled = !slot.isAvailable;
              return GestureDetector(
                onTap: disabled ? null : () => onSelect(slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: disabled
                        ? AppColors.surfaceElevatedOf(context)
                        : isSelected
                        ? AppColors.primary
                        : AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.cardBorderOf(context),
                    ),
                  ),
                  child: Text(
                    slot.label,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: disabled
                          ? AppColors.textHintOf(context)
                          : isSelected
                          ? Colors.white
                          : AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _AddressStep extends StatelessWidget {
  final List<AddressModel> addresses;
  final AddressModel? selected;
  final bool isLoading;
  final ValueChanged<AddressModel> onSelect;
  final VoidCallback onAddAddress;
  final Future<void> Function() onRefresh;

  const _AddressStep({
    required this.addresses,
    required this.selected,
    required this.isLoading,
    required this.onSelect,
    required this.onAddAddress,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StepHeader(
                title: AppStrings.selectAddress,
                subtitle: 'Choose where the booking should be assigned.',
              ),
            ),
            TextButton(onPressed: onAddAddress, child: const Text('+ Add New')),
          ],
        ),
        const SizedBox(height: 18),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (addresses.isEmpty)
          _EmptyAddresses(onAddAddress: onAddAddress)
        else
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: onRefresh,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final address = addresses[index];
                final isSelected = selected?.id == address.id;
                return _AddressCard(
                  address: address,
                  isSelected: isSelected,
                  onTap: () => onSelect(address),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  final VoidCallback onAddAddress;

  const _EmptyAddresses({required this.onAddAddress});

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      icon: Icons.location_off_outlined,
      message: 'Add a saved address to continue with your booking.',
      action: AppButton(label: 'Add Address', onPressed: onAddAddress),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.06)
                : AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.cardBorderOf(context),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  address.label.toLowerCase() == 'home'
                      ? Icons.home_outlined
                      : address.label.toLowerCase() == 'office'
                      ? Icons.work_outline
                      : Icons.location_on_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Default',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.fullAddress,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_off,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textHintOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStep extends StatelessWidget {
  final BookingProvider booking;
  final double walletBalance;

  const _SummaryStep({required this.booking, required this.walletBalance});

  @override
  Widget build(BuildContext context) {
    final amount = booking.totalAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(
          title: 'Booking Summary',
          subtitle:
              'Review the booking details before you continue to confirmation.',
        ),
        const SizedBox(height: 18),
        _PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.selectedService?.name ?? '',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                booking.selectedPackage?.name ?? '',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 14),
              _SummaryRow(
                'Date',
                booking.selectedDate != null
                    ? Formatters.date(booking.selectedDate!)
                    : '',
              ),
              _SummaryRow('Time', booking.selectedSlot?.label ?? ''),
              _SummaryRow(
                'Address',
                booking.selectedAddress?.fullAddress ?? '',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 12),
              ...PaymentMethod.values.map((method) {
                final selected = booking.selectedPaymentMethod == method;
                final isWalletUnavailable =
                    method == PaymentMethod.wallet && walletBalance < amount;
                final subtitle = method == PaymentMethod.wallet
                    ? 'Wallet balance: ${Formatters.currency(walletBalance)}'
                    : method == PaymentMethod.cash
                    ? 'Pay at the salon after your appointment'
                    : 'Continue in secure Razorpay checkout';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: isWalletUnavailable
                        ? null
                        : () => booking.selectPaymentMethod(method),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.06)
                            : AppColors.surfaceElevatedOf(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.cardBorderOf(context),
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHintOf(context),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method.label,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: isWalletUnavailable
                                        ? AppColors.textSecondaryOf(context)
                                        : AppColors.textPrimaryOf(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isWalletUnavailable
                                      ? 'Insufficient wallet balance. Top up first or choose another method.'
                                      : subtitle,
                                  style: AppTextStyles.bodySmall.copyWith(
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
                );
              }),
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  Text(Formatters.currency(amount), style: AppTextStyles.price),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StepHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }
}

class _PanelCard extends StatelessWidget {
  final Widget child;

  const _PanelCard({required this.child});

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
      child: child,
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _MessageCard({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderOf(context)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.textHintOf(context)),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
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
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
