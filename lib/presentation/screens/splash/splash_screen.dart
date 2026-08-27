import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/app_icons.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gradient_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _minSplash = Duration(milliseconds: 1200);
  static const _maxSplash = Duration(seconds: 8);

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storage = context.read<TokenStorage>();
    final auth = context.read<AuthProvider>();
    bool restored = false;

    final safetyTimer = Timer(_maxSplash, () {
      if (!_navigated && mounted) {
        AppLogger.warning('Splash timeout — forcing navigation');
        _goToNext(restored);
      }
    });

    try {
      await Future.wait([Future.delayed(_minSplash), storage.init()]);
      if (!mounted) return;

      restored = await auth.restoreSession();
    } catch (e) {
      AppLogger.warning('Splash bootstrap failed: $e');
    } finally {
      safetyTimer.cancel();
    }

    if (!mounted) return;
    _goToNext(restored);
  }

  void _goToNext(bool restored) async {
    if (_navigated || !mounted) return;
    _navigated = true;
    final hasToken = await context.read<TokenStorage>().hasToken();
    final route = (restored || hasToken)
        ? AppRoutes.main
        : AppRoutes.phoneLogin;
    AppLogger.info('Splash → $route', tag: 'App');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(top: -40, right: -30, child: _sparkle(140, 0.08)),
          Positioned(bottom: 60, left: -50, child: _sparkle(100, 0.06)),
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: AppDecorations.buttonShadow(context),
                    ),
                    child: const Icon(
                      AppIcons.brand,
                      size: 48,
                      color: AppColors.textOnGold,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GradientText(
                    text: 'GLOWVAX',
                    style: AppTextStyles.brandTitle.copyWith(fontSize: 42),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppConstants.appTagline,
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sparkle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
