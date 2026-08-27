import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/service_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/service_repository.dart';

class SearchProvider extends ChangeNotifier {
  final ServiceRepository _repository;

  SearchProvider(this._repository);

  List<ServiceModel> _results = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String _query = '';
  String? _error;
  int _searchSeq = 0;

  static const _searchTimeout = Duration(seconds: 25);

  List<ServiceModel> get results => _results;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String get query => _query;
  String? get error => _error;

  Future<void> search(String query, {bool force = false}) async {
    final trimmed = query.trim();
    if (!force && _isLoading && _query == trimmed) return;

    final seq = ++_searchSeq;
    _query = trimmed;
    _isLoading = true;
    _error = null;
    notifyListeners();

    AppLogger.state('SearchProvider', 'search', data: {'query': trimmed});
    try {
      final results = await _repository
          .searchServices(trimmed)
          .timeout(_searchTimeout, onTimeout: () => <ServiceModel>[]);
      if (seq != _searchSeq) return;

      _results = trimmed.isEmpty
          ? _dedupe(results)
          : filterLocally(results, trimmed);
      _hasLoaded = true;
      if (_results.isEmpty && trimmed.isNotEmpty) {
        _error = null;
      }
      AppLogger.success('SearchProvider: ${_results.length} results');
    } catch (e) {
      if (seq != _searchSeq) return;
      _error = e is ApiException ? e.message : e.toString();
      AppLogger.error('Search failed', e);
      if (_results.isEmpty) _results = [];
    } finally {
      if (seq == _searchSeq) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<List<ServiceModel>> getByCategory(ServiceCategoryType category) async {
    final categoryModel = CategoryModel(
      id: category.name,
      name: category.label,
      type: category,
      description: '',
      serviceCount: 0,
      colorHex: '',
    );
    return getByCategoryModel(categoryModel);
  }

  Future<List<ServiceModel>> getByCategoryModel(CategoryModel category) async {
    AppLogger.state(
      'SearchProvider',
      'getByCategory',
      data: {'category': category.name},
    );
    try {
      final typedResults = await _repository
          .getServicesByCategory(category.type)
          .timeout(_searchTimeout, onTimeout: () => <ServiceModel>[]);
      final refinedTyped = filterCategoryResults(typedResults, category);
      if (refinedTyped.isNotEmpty) return refinedTyped;

      final searchedResults = await _repository
          .searchServices(category.name)
          .timeout(_searchTimeout, onTimeout: () => <ServiceModel>[]);
      final refinedSearch = filterCategoryResults(searchedResults, category);
      if (refinedSearch.isNotEmpty) return refinedSearch;

      return filterLocally(searchedResults, category.name);
    } catch (e) {
      AppLogger.error('Category load failed', e);
      rethrow;
    }
  }

  List<ServiceModel> filterLocally(List<ServiceModel> services, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return _dedupe(services);
    return _dedupe(services.where((service) => _matchesQuery(service, trimmed)));
  }

  List<ServiceModel> filterCategoryResults(
    List<ServiceModel> services,
    CategoryModel category,
  ) {
    return _dedupe(
      services.where((service) => _matchesCategory(service, category)),
    );
  }

  List<ServiceModel> _dedupe(Iterable<ServiceModel> services) {
    final seen = <String>{};
    final results = <ServiceModel>[];
    for (final service in services) {
      if (seen.add(service.id)) {
        results.add(service);
      }
    }
    return results;
  }

  bool _matchesQuery(ServiceModel service, String query) {
    final haystack = _searchText(service);
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    return terms.every(haystack.contains);
  }

  bool _matchesCategory(ServiceModel service, CategoryModel category) {
    final requestedId = category.id.trim().toLowerCase();
    final requestedName = category.name.trim().toLowerCase();
    final requestedLabel = category.type.label.trim().toLowerCase();
    final serviceCategoryId = service.categoryId?.trim().toLowerCase() ?? '';
    final serviceCategoryName =
        service.categoryName?.trim().toLowerCase() ?? '';
    final tagSet = service.tags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet();

    if (requestedId.isNotEmpty &&
        serviceCategoryId.isNotEmpty &&
        requestedId == serviceCategoryId) {
      return true;
    }

    if (serviceCategoryName.isNotEmpty) {
      if (serviceCategoryName == requestedName ||
          serviceCategoryName == requestedLabel) {
        return true;
      }
      if (serviceCategoryName.contains(requestedName) ||
          requestedName.contains(serviceCategoryName)) {
        return true;
      }
    }

    if (tagSet.contains(requestedName) || tagSet.contains(requestedLabel)) {
      return true;
    }

    final hasExplicitCategoryMeta =
        serviceCategoryId.isNotEmpty ||
        serviceCategoryName.isNotEmpty ||
        tagSet.isNotEmpty;
    if (hasExplicitCategoryMeta) {
      return false;
    }

    return service.category == category.type;
  }

  String _searchText(ServiceModel service) {
    return [
      service.name,
      service.description,
      service.categoryName,
      service.category.label,
      ...service.tags,
    ].whereType<String>().join(' ').toLowerCase();
  }
}
