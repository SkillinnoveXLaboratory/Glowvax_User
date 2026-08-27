import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.pageGradientOf(context)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(top: -40, right: -30, child: _sparkle(context, 140, 0.14)),
          Positioned(top: 180, left: -46, child: _sparkle(context, 110, 0.1)),
          Positioned(
            bottom: 96,
            right: -12,
            child: _sparkle(context, 100, 0.12),
          ),
          child,
        ],
      ),
    );
  }

  Widget _sparkle(BuildContext context, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: opacity),
            AppColors.gold.withValues(alpha: opacity * 0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
