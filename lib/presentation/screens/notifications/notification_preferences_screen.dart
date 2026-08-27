import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/notification_provider.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final prefs = provider.preferences;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Booking Updates', style: AppTextStyles.titleMedium),
            subtitle: const Text('Status changes, reminders'),
            value: prefs.bookingUpdates,
            activeThumbColor: AppColors.primary,
            onChanged: (v) =>
                provider.updatePreferences(prefs.copyWith(bookingUpdates: v)),
          ),
          SwitchListTile(
            title: Text('Promotions', style: AppTextStyles.titleMedium),
            subtitle: const Text('Offers and deals'),
            value: prefs.promotions,
            activeThumbColor: AppColors.primary,
            onChanged: (v) =>
                provider.updatePreferences(prefs.copyWith(promotions: v)),
          ),
          SwitchListTile(
            title: Text('Wallet Alerts', style: AppTextStyles.titleMedium),
            subtitle: const Text('Payments and top-ups'),
            value: prefs.walletAlerts,
            activeThumbColor: AppColors.primary,
            onChanged: (v) =>
                provider.updatePreferences(prefs.copyWith(walletAlerts: v)),
          ),
          SwitchListTile(
            title: Text('Reminders', style: AppTextStyles.titleMedium),
            subtitle: const Text('Appointment reminders'),
            value: prefs.reminders,
            activeThumbColor: AppColors.primary,
            onChanged: (v) =>
                provider.updatePreferences(prefs.copyWith(reminders: v)),
          ),
        ],
      ),
    );
  }
}
