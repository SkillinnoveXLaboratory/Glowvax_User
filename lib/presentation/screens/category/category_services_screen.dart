import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/service_model.dart';
import '../../providers/search_provider.dart';
import '../../widgets/home/service_card.dart';

class CategoryServicesScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryServicesScreen({super.key, required this.category});

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  List<ServiceModel> _services = [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    final services = await context.read<SearchProvider>().getByCategory(
      widget.category.type,
    );
    if (mounted) {
      setState(() {
        _services = services;
        _isLoading = false;
        _hasLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: _isLoading && !_hasLoaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.cardBorderOf(context),
                      ),
                    ),
                    child: Text(
                      category.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _services.isEmpty
                      ? Center(
                          child: Text(
                            'No services found in this category',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            return ServiceListTile(
                              service: service,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.serviceDetail,
                                arguments: service,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
