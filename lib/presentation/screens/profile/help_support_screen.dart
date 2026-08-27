import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  late final Future<Map<String, dynamic>> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();
  }

  Future<Map<String, dynamic>> _loadSettings() async {
    final response = await ApiClient().get(ApiConstants.settingsPublic);
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  Future<void> _copyValue(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final settings = snapshot.data ?? <String, dynamic>{};
          final supportEmail =
              settings['platform_contact_email']?.toString() ?? '';
          final supportPhone =
              settings['platform_contact_phone']?.toString() ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need help with your booking or payment?',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reach support using the contact details below. You can also copy them for quick use in your phone dialer or email app.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (supportEmail.isNotEmpty)
                _ContactCard(
                  icon: Icons.mail_outline_rounded,
                  title: 'Support Email',
                  value: supportEmail,
                  onCopy: () => _copyValue('Support email', supportEmail),
                ),
              if (supportPhone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _ContactCard(
                    icon: Icons.call_outlined,
                    title: 'Support Phone',
                    value: supportPhone,
                    onCopy: () => _copyValue('Support phone', supportPhone),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick help',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _HelpPoint(
                        title: 'Payment issues',
                        body: 'If a payment succeeds but the booking does not update, open My Bookings and refresh once before contacting support.',
                      ),
                      const _HelpPoint(
                        title: 'Refunds',
                        body: 'Refunds are credited to your Glowvax wallet when the backend approves the request.',
                      ),
                      const _HelpPoint(
                        title: 'Booking changes',
                        body: 'Use the booking detail screen to reschedule, cancel, or review the status of an appointment.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (supportEmail.isNotEmpty || supportPhone.isNotEmpty)
                AppButton(
                  label: 'Copy Support Details',
                  onPressed: () async {
                    final text = [
                      if (supportEmail.isNotEmpty) supportEmail,
                      if (supportPhone.isNotEmpty) supportPhone,
                    ].join('\n');
                    await _copyValue('Support details', text);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onCopy;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        subtitle: SelectableText(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        trailing: IconButton(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded),
        ),
      ),
    );
  }
}

class _HelpPoint extends StatelessWidget {
  final String title;
  final String body;

  const _HelpPoint({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
