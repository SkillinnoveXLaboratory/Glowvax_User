import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/service_model.dart';
import '../../providers/search_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/home/service_card.dart';

class CategoryServicesScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryServicesScreen({super.key, required this.category});

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  final _searchController = TextEditingController();
  List<ServiceModel> _services = [];
  List<ServiceModel> _filteredServices = [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    final provider = context.read<SearchProvider>();
    final services = await provider.getByCategoryModel(widget.category);
    if (mounted) {
      setState(() {
        _services = services;
        _filteredServices = services;
        _isLoading = false;
        _hasLoaded = true;
      });
    }
  }

  void _applySearch(String query) {
    final provider = context.read<SearchProvider>();
    setState(() {
      _filteredServices = provider.filterLocally(_services, query);
    });
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
                  child: Column(
                    children: [
                      Container(
                        decoration: AppDecorations.searchBar(context),
                        child: AppTextField(
                          controller: _searchController,
                          hint: 'Search in ${category.name}',
                          onChanged: _applySearch,
                          prefix: Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '${_filteredServices.length} results',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                          const Spacer(),
                          if (_searchController.text.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                _applySearch('');
                              },
                              child: const Text('Clear'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredServices.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'No services found in this category'
                                : 'No matching services found',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = _filteredServices[index];
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
