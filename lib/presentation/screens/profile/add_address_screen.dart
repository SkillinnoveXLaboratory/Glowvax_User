import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/address_model.dart';
import '../../../data/repositories/address_repository.dart';
import '../../widgets/common/app_button.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController(text: 'Mumbai');
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _setAsDefault = false;
  bool _isLoading = false;
  bool _initialized = false;
  AddressModel? _editing;

  bool get _isEditMode => _editing != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AddressModel) {
      _editing = args;
      _labelController.text = args.label;
      _line1Controller.text = args.line1;
      _line2Controller.text = args.line2;
      _cityController.text = args.city;
      _stateController.text = args.state;
      _pincodeController.text = args.pincode;
      _setAsDefault = args.isDefault;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final repository = context.read<AddressRepository>();

    final address = AddressModel(
      id: _editing?.id ?? 'addr_${DateTime.now().millisecondsSinceEpoch}',
      label: _labelController.text.trim(),
      line1: _line1Controller.text.trim(),
      line2: _line2Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      isDefault: _setAsDefault,
    );

    try {
      final saved = _isEditMode
          ? await repository.updateAddress(address)
          : await repository.addAddress(address);
      if (_setAsDefault) {
        await repository.setDefaultAddress(saved.id);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save address. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimaryOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Address' : 'Add Address')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditMode
                    ? 'Update saved address'
                    : 'Add a new service address',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Label'),
                validator: (v) => Validators.required(v, field: 'Label'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _line1Controller,
                decoration: const InputDecoration(labelText: 'Address Line 1'),
                validator: (v) => Validators.required(v, field: 'Address'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _line2Controller,
                decoration: const InputDecoration(labelText: 'Address Line 2'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) => Validators.required(v, field: 'City'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State'),
                validator: (v) => Validators.required(v, field: 'State'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode'),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (v) => Validators.required(v, field: 'Pincode'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _setAsDefault,
                activeThumbColor: AppColors.primary,
                title: Text(
                  'Set as default address',
                  style: AppTextStyles.titleMedium.copyWith(color: textColor),
                ),
                subtitle: Text(
                  'Use this address first during booking',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                onChanged: (value) => setState(() => _setAsDefault = value),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: _isEditMode ? 'Save Changes' : 'Save Address',
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
