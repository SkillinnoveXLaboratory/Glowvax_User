import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/payment/razorpay_payment_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/wallet_transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/premium_bottom_nav.dart';
import '../../widgets/common/premium_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  void _showAddMoneySheet(WalletProvider wallet) {
    showPremiumBottomSheet(
      context: context,
      title: AppStrings.addMoney,
      child: _AddMoneySheet(
        amounts: wallet.topupOptions.isNotEmpty
            ? wallet.topupOptions
            : [99, 199, 499, 999],
        onAdd: (amount) async {
          final provider = context.read<WalletProvider>();
          final user = context.read<AuthProvider>().user;
          final ok = await provider.topUp(
            amount: amount,
            razorpay: context.read<RazorpayPaymentService>(),
            contact: user?.phone ?? '',
            email: user?.email,
          );
          if (!mounted) return;
          if (ok) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wallet topped up successfully'),
                backgroundColor: AppColors.success,
              ),
            );
          } else {
            final message =
                provider.error ?? 'Could not add money. Please try again.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final isDark = AppColors.isDark(context);
    final heroTitleColor = isDark
        ? AppColors.textOnDark
        : AppColors.textPrimaryOf(context);
    final heroSubtitleColor = isDark
        ? AppColors.textOnDark.withValues(alpha: 0.78)
        : AppColors.textSecondaryOf(context);
    final heroLabelColor = isDark
        ? AppColors.textOnDark.withValues(alpha: 0.72)
        : AppColors.textSecondaryOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.wallet)),
      body: wallet.isLoading && !wallet.hasLoaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: wallet.loadWallet,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: PremiumHeroCard(
                      margin: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.walletBalance,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: heroLabelColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.currency(wallet.balance),
                            style: AppTextStyles.displayLarge.copyWith(
                              color: heroTitleColor,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Top up securely and use wallet balance during checkout.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: heroSubtitleColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppButton(
                            label: AppStrings.addMoney,
                            isLoading: wallet.isAddingMoney,
                            onPressed: wallet.isAddingMoney
                                ? null
                                : () => _showAddMoneySheet(wallet),
                            icon: Icons.add,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.transactions,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ),
                          if (wallet.transactions.isNotEmpty)
                            Text(
                              '${wallet.transactions.length} items',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  if (wallet.transactions.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.defaultPadding,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.cardBorderOf(context),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 40,
                                color: AppColors.textHintOf(context),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No transactions yet',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.textPrimaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your wallet top-ups and booking refunds will appear here.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondaryOf(context),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final txn = wallet.transactions[index];
                        return _TransactionTile(transaction: txn);
                      }, childCount: wallet.transactions.length),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorderOf(context)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isCredit
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          transaction.title,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        subtitle: Text(
          '${transaction.description} - ${Formatters.date(transaction.createdAt)}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'}${Formatters.currency(transaction.amount)}',
          style: AppTextStyles.titleLarge.copyWith(color: color),
        ),
      ),
    );
  }
}

class _AddMoneySheet extends StatefulWidget {
  final List<double> amounts;
  final Future<void> Function(double) onAdd;

  const _AddMoneySheet({required this.amounts, required this.onAdd});

  @override
  State<_AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends State<_AddMoneySheet> {
  double? _loadingAmount;

  Future<void> _handleAdd(double amount) async {
    setState(() => _loadingAmount = amount);
    try {
      await widget.onAdd(amount);
    } finally {
      if (mounted) {
        setState(() => _loadingAmount = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.addMoney,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an amount and continue in Razorpay checkout.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Text(
              'Wallet balance is updated after successful payment verification. If the payment is interrupted, no money is added until the server confirms it.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondaryOf(context),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.amounts.map((amount) {
              final isLoading = _loadingAmount == amount;
              final disabled = _loadingAmount != null && !isLoading;
              return GestureDetector(
                onTap: disabled || isLoading ? null : () => _handleAdd(amount),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 110,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isLoading
                        ? AppColors.surfaceElevatedOf(context)
                        : AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isLoading
                          ? AppColors.primary
                          : AppColors.cardBorderOf(context),
                      width: isLoading ? 1.6 : 1,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Text(
                              Formatters.currency(amount),
                              style: AppTextStyles.titleLarge.copyWith(
                                color: disabled
                                    ? AppColors.textHintOf(context)
                                    : AppColors.textPrimaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add now',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: disabled
                                    ? AppColors.textHintOf(context)
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
