import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/premium_card.dart';
import '../../widgets/common/premium_background.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(_otpController.text);
    if (!mounted) return;

    if (success) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final phone = auth.pendingPhone ?? '';

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(AppStrings.verifyOtp, style: AppTextStyles.displayLarge),
                  const SizedBox(height: 8),
                  Text(
                    '${AppStrings.otpSent} ${Formatters.phone(phone)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  PremiumCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: AppConstants.otpLength,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) =>
                              Validators.otp(v, length: AppConstants.otpLength),
                          style: AppTextStyles.displayLarge.copyWith(
                            letterSpacing: 14,
                            color: AppColors.primary,
                          ),
                          decoration: const InputDecoration(
                            hintText: '• • • • • •',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: AppStrings.verifyOtp,
                          isLoading: auth.isLoading,
                          onPressed: _verifyOtp,
                          screenName: AppRoutes.otpVerification,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: auth.isLoading ? null : () => auth.resendOtp(),
                      child: Text(
                        AppStrings.resendOtp,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
