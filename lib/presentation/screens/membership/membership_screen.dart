import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/payment/razorpay_payment_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/membership_plan_model.dart';
import '../../../data/models/payment_models.dart';
import '../../../data/models/user_membership_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/membership_provider.dart';
import '../../widgets/common/app_button.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MembershipProvider>().loadPlans();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membership = context.watch<MembershipProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.membership),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Plans'),
            Tab(text: 'My Membership'),
          ],
        ),
      ),
      body: membership.isLoading && !membership.hasLoaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : membership.error != null && !membership.hasLoaded
          ? _ErrorState(
              message: membership.error!,
              onRetry: membership.loadPlans,
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _PlansTab(
                  membership: membership,
                  onSubscribed: () => _tabController.animateTo(1),
                ),
                _MyMembershipTab(
                  membership: membership,
                  onBrowsePlans: () => _tabController.animateTo(0),
                ),
              ],
            ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _PlansTab extends StatelessWidget {
  final MembershipProvider membership;
  final VoidCallback onSubscribed;

  const _PlansTab({required this.membership, required this.onSubscribed});

  @override
  Widget build(BuildContext context) {
    if (membership.plans.isEmpty) {
      return Center(
        child: Text(
          'No membership plans available',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondaryOf(context),
          ),
        ),
      );
    }

    final subtitle = membership.maxPlanDiscount > 0
        ? 'Save up to ${membership.maxPlanDiscount.toInt()}% on bookings'
        : membership.plans.first.description;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: membership.loadPlans,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  AppIcons.membership,
                  size: 44,
                  color: AppColors.textOnGold,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.choosePlan,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textOnGold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textOnGold.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...membership.plans.map(
            (plan) => _PlanCard(
              plan: plan,
              isActive: membership.activePlanId == plan.id,
              isSelected: membership.selectedPlanId == plan.id,
              isSubscribing: membership.isSubscribing,
              onSelect: () => membership.selectPlan(plan.id),
              onSubscribe: () => _showPaymentSheet(context, plan),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentSheet(
    BuildContext context,
    MembershipPlanModel plan,
  ) async {
    final auth = context.read<AuthProvider>();
    final razorpay = context.read<RazorpayPaymentService>();
    final provider = context.read<MembershipProvider>();
    provider.selectPlan(plan.id);

    final method = await showModalBottomSheet<PaymentMethod>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _PaymentMethodSheet(
        plan: plan,
        walletBalance: provider.walletBalance,
      ),
    );

    if (method == null || !context.mounted) return;

    final success = await provider.subscribe(
      plan: plan,
      paymentMethod: method,
      razorpay: razorpay,
      contact: auth.user?.phone ?? auth.pendingPhone ?? '',
      email: auth.user?.email,
    );

    if (!context.mounted) return;

    if (success) {
      onSubscribed();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscribed to ${plan.name} successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: AppColors.error,
        ),
      );
      provider.clearError();
    }
  }
}

class _PaymentMethodSheet extends StatelessWidget {
  final MembershipPlanModel plan;
  final double walletBalance;

  const _PaymentMethodSheet({required this.plan, required this.walletBalance});

  @override
  Widget build(BuildContext context) {
    final methods = [PaymentMethod.razorpay, PaymentMethod.wallet];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscribe to ${plan.name}',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.currency(plan.price),
                    style: AppTextStyles.price.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Valid for ${plan.durationLabel}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  if (plan.discountPercent > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${plan.discountPercent.toInt()}% discount included',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Choose payment method',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 12),
            ...methods.map((method) {
              final canUseWallet =
                  method != PaymentMethod.wallet || walletBalance >= plan.price;
              final subtitle = method == PaymentMethod.wallet
                  ? 'Available balance: ${Formatters.currency(walletBalance)}'
                  : 'Continue in secure Razorpay checkout';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: canUseWallet
                      ? () => Navigator.pop(context, method)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: canUseWallet
                          ? AppColors.surfaceOf(context)
                          : AppColors.surfaceElevatedOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: canUseWallet
                            ? AppColors.cardBorderOf(context)
                            : AppColors.cardBorderOf(context)
                                  .withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: canUseWallet
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.textHintOf(context)
                                      .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            method == PaymentMethod.wallet
                                ? Icons.account_balance_wallet_outlined
                                : Icons.payment_rounded,
                            color: canUseWallet
                                ? AppColors.primary
                                : AppColors.textHintOf(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method.label,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: canUseWallet
                                      ? AppColors.textPrimaryOf(context)
                                      : AppColors.textSecondaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                canUseWallet ? subtitle : 'Insufficient wallet balance. Please top up first.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: canUseWallet
                              ? AppColors.primary
                              : AppColors.textHintOf(context),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MyMembershipTab extends StatelessWidget {
  final MembershipProvider membership;
  final VoidCallback onBrowsePlans;

  const _MyMembershipTab({
    required this.membership,
    required this.onBrowsePlans,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: membership.loadPlans,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          if (membership.activeMembership != null) ...[
            _ActiveMembershipCard(
              membership: membership.activeMembership!,
              benefits: membership.benefits,
              onCancel: () => _confirmCancel(context),
            ),
            const SizedBox(height: 24),
          ],
          if (membership.history.isNotEmpty) ...[
            Text(
              'Membership History',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 12),
            ...membership.history.map((item) => _HistoryCard(membership: item)),
          ],
          if (membership.activeMembership == null && membership.history.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Column(
                  children: [
                    Icon(
                      Icons.card_membership_outlined,
                      size: 64,
                      color: AppColors.textSecondaryOf(context)
                          .withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active membership',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Subscribe to a plan to unlock exclusive discounts and benefits.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppButton(label: 'Browse Plans', onPressed: onBrowsePlans),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Membership'),
        content: const Text(
          'Are you sure you want to cancel your active membership?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await membership.cancelMembership();
    if (!context.mounted) return;

    if (membership.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(membership.error!),
          backgroundColor: AppColors.error,
        ),
      );
      membership.clearError();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Membership cancelled'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _ActiveMembershipCard extends StatelessWidget {
  final UserMembershipModel membership;
  final List<String> benefits;
  final VoidCallback onCancel;

  const _ActiveMembershipCard({
    required this.membership,
    required this.benefits,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final displayBenefits = benefits.isNotEmpty
        ? benefits
        : membership.benefits;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  membership.planName,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Status: ${membership.status}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Started ${Formatters.date(membership.startDate)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Valid until ${Formatters.date(membership.endDate)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          if (membership.discountPercent > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${membership.discountPercent.toInt()}% discount on bookings',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
            ),
          ],
          if (displayBenefits.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Your Benefits',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 8),
            ...displayBenefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: 'Cancel Membership',
            isOutlined: true,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final UserMembershipModel membership;

  const _HistoryCard({required this.membership});

  @override
  Widget build(BuildContext context) {
    final statusColor = membership.isActive
        ? AppColors.success
        : AppColors.textSecondaryOf(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  membership.planName,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  membership.status.toUpperCase(),
                  style: AppTextStyles.labelMedium.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${Formatters.date(membership.startDate)} - ${Formatters.date(membership.endDate)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final MembershipPlanModel plan;
  final bool isActive;
  final bool isSelected;
  final bool isSubscribing;
  final VoidCallback onSelect;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.isActive,
    required this.isSelected,
    required this.isSubscribing,
    required this.onSelect,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.primary
        : plan.isPopular
        ? AppColors.gold
        : AppColors.cardBorderOf(context);

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.cardGradientOf(context) : null,
          color: isSelected ? null : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.8 : (plan.isPopular ? 1.5 : 1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                if (plan.isPopular) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'POPULAR',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isActive)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  )
                else
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textHintOf(context),
                  ),
              ],
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                plan.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(plan.price),
                  style: AppTextStyles.price,
                ),
                const SizedBox(width: 4),
                Text(
                  '/ ${plan.durationLabel}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                const Spacer(),
                if (plan.discountPercent > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${plan.discountPercent.toInt()}% OFF',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...plan.benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected && !isActive) ...[
              const SizedBox(height: 4),
              Text(
                'Selected plan',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (!isActive)
              AppButton(
                label: AppStrings.subscribe,
                isLoading: isSubscribing,
                onPressed: isSubscribing ? null : onSubscribe,
              ),
          ],
        ),
      ),
    );
  }
}
