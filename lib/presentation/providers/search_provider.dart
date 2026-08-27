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

      _results = results;
      _hasLoaded = true;
      if (results.isEmpty && trimmed.isNotEmpty) {
        _error = null;
      }
      AppLogger.success('SearchProvider: ${results.length} results');
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
    AppLogger.state(
      'SearchProvider',
      'getByCategory',
      data: {'category': category.label},
    );
    return _repository
        .getServicesByCategory(category)
        .timeout(_searchTimeout, onTimeout: () => <ServiceModel>[]);
  }
}
