import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/service_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/time_slot_model.dart';
import '../../data/repositories/service_repository.dart';

class HomeProvider extends ChangeNotifier {
  final ServiceRepository _repository;

  HomeProvider(this._repository);

  List<CategoryModel> _categories = [];
  List<ServiceModel> _featuredServices = [];
  List<ServiceModel> _topRatedServices = [];
  List<OfferBannerModel> _banners = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  List<ServiceModel> get featuredServices => _featuredServices;
  List<ServiceModel> get topRatedServices => _topRatedServices;
  List<OfferBannerModel> get banners => _banners;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get hasContent =>
      _categories.isNotEmpty ||
      _featuredServices.isNotEmpty ||
      _topRatedServices.isNotEmpty;
  String? get error => _error;

  static const _sectionTimeout = Duration(seconds: 20);

  Future<void> loadHomeData({bool force = false}) async {
    if (_isLoading && !force) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    AppLogger.state('HomeProvider', 'loadHomeData.start');
    try {
      try {
        _categories = await _repository
            .getCategories(forceRefresh: force)
            .timeout(_sectionTimeout, onTimeout: () => <CategoryModel>[]);
      } catch (e) {
        AppLogger.warning('Categories load failed: $e');
      }
      notifyListeners();

      final featuredOk = await _loadFeatured(force: force);
      final bannersOk = await _loadBanners(force: force);
      final topRatedOk = await _loadTopRated(force: force);

      if (_categories.isEmpty &&
          _featuredServices.isEmpty &&
          _topRatedServices.isEmpty &&
          !featuredOk &&
          !bannersOk &&
          !topRatedOk) {
        _error = 'Could not load home content. Pull to refresh.';
      }
      AppLogger.success(
        'HomeProvider: loaded ${_categories.length} categories, ${_featuredServices.length} featured',
      );
    } catch (e) {
      _error = e is ApiException ? e.message : e.toString();
      AppLogger.error('HomeProvider load failed', e);
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  Future<bool> _loadFeatured({bool force = false}) async {
    try {
      _featuredServices = await _repository
          .getFeaturedServices(forceRefresh: force)
          .timeout(_sectionTimeout, onTimeout: () => <ServiceModel>[]);
      notifyListeners();
      return _featuredServices.isNotEmpty;
    } catch (e) {
      AppLogger.warning('Featured services load failed: $e');
      return false;
    }
  }

  Future<bool> _loadBanners({bool force = false}) async {
    try {
      _banners = await _repository
          .getBanners(forceRefresh: force)
          .timeout(_sectionTimeout, onTimeout: () => <OfferBannerModel>[]);
      notifyListeners();
      return _banners.isNotEmpty;
    } catch (e) {
      AppLogger.warning('Banners load failed: $e');
      return false;
    }
  }

  Future<bool> _loadTopRated({bool force = false}) async {
    try {
      _topRatedServices = await _repository
          .getTopRatedServices(forceRefresh: force)
          .timeout(_sectionTimeout, onTimeout: () => <ServiceModel>[]);
      notifyListeners();
      return _topRatedServices.isNotEmpty;
    } catch (e) {
      AppLogger.warning('Top rated load failed: $e');
      return false;
    }
  }
}
