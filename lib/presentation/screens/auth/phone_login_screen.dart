import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/premium_card.dart';
import '../../widgets/common/premium_background.dart';
import '../../widgets/common/gradient_text.dart';
import '../../../core/utils/app_icons.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(_phoneController.text);
    if (!mounted) return;

    if (success) {
      Navigator.pushNamed(context, AppRoutes.otpVerification);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            AppIcons.brand,
                            size: 40,
                            color: AppColors.textOnGold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GradientText(
                          text: 'GLOWVAX',
                          style: AppTextStyles.brandTitle.copyWith(
                            fontSize: 36,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Luxury beauty at your doorstep',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    AppStrings.loginTitle,
                    style: AppTextStyles.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.loginSubtitle,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  PremiumCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.enterPhone,
                          style: AppTextStyles.titleLarge,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: Validators.phone,
                          style: AppTextStyles.bodyLarge,
                          decoration: InputDecoration(
                            prefixIcon: Container(
                              width: 70,
                              alignment: Alignment.center,
                              child: Text(
                                '+91',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            hintText: '9876543210',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          label: AppStrings.sendOtp,
                          isLoading: auth.isLoading,
                          onPressed: _sendOtp,
                          screenName: AppRoutes.phoneLogin,
                        ),
                      ],
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
