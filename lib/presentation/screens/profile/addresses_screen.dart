import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/address_model.dart';
import '../../../data/repositories/address_repository.dart';
import '../../widgets/common/app_button.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<AddressModel> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final addresses = await context.read<AddressRepository>().getAddresses();
    if (!mounted) return;
    setState(() {
      _addresses = addresses;
      _isLoading = false;
    });
  }

  Future<void> _openEditor([AddressModel? address]) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.addAddress,
      arguments: address,
    );
    if (changed == true) {
      _loadAddresses();
    }
  }

  Future<void> _setDefault(AddressModel address) async {
    await context.read<AddressRepository>().setDefaultAddress(address.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default address updated'),
        backgroundColor: AppColors.success,
      ),
    );
    _loadAddresses();
  }

  Future<void> _delete(AddressModel address) async {
    await context.read<AddressRepository>().deleteAddress(address.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address removed'),
        backgroundColor: AppColors.success,
      ),
    );
    _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myAddresses),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _addresses.isEmpty
          ? EmptyStateWidget(
              title: 'No saved addresses',
              subtitle: 'Add an address so booking and checkout stay quick.',
              icon: Icons.location_on_outlined,
              actionLabel: 'Add Address',
              onAction: () => _openEditor(),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadAddresses,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final address = _addresses[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
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
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        address.label,
                                        style: AppTextStyles.titleLarge
                                            .copyWith(
                                              color: AppColors.textPrimaryOf(
                                                context,
                                              ),
                                            ),
                                      ),
                                    ),
                                    if (address.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          'Default',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                                color: AppColors.primary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _openEditor(address);
                                      break;
                                    case 'default':
                                      _setDefault(address);
                                      break;
                                    case 'delete':
                                      _delete(address);
                                      break;
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  if (!address.isDefault)
                                    const PopupMenuItem(
                                      value: 'default',
                                      child: Text('Set as default'),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            address.fullAddress,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                          if (!address.isDefault) ...[
                            const SizedBox(height: 14),
                            AppButton(
                              label: 'Set as Default',
                              isOutlined: true,
                              onPressed: () => _setDefault(address),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
