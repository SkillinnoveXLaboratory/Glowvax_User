import 'package:flutter/material.dart';

class AppIcons {
  AppIcons._();

  static const IconData brand = Icons.auto_awesome_rounded;
  static const IconData membership = Icons.workspace_premium_rounded;

  static const Map<String, IconData> _icons = {
    'salon': Icons.content_cut_rounded,
    'spa': Icons.spa_rounded,
    'grooming': Icons.face_retouching_natural_rounded,
    'tattoo': Icons.brush_rounded,
    'nails': Icons.back_hand_rounded,
    'wellness': Icons.eco_rounded,
    'offer': Icons.local_offer_rounded,
    'membership': Icons.workspace_premium_rounded,
    'celebration': Icons.celebration_rounded,
    'brand': Icons.auto_awesome_rounded,
    'partner': Icons.storefront_rounded,
  };

  static IconData fromName(
    String name, {
    IconData fallback = Icons.spa_rounded,
  }) {
    return _icons[name] ?? fallback;
  }

  static Widget icon(
    String name, {
    double size = 32,
    Color? color,
    IconData fallback = Icons.spa_rounded,
  }) {
    return Icon(
      fromName(name, fallback: fallback),
      size: size,
      color: color,
    );
  }
}
