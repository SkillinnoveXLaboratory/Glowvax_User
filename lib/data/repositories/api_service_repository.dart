import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_constants.dart';
import '../mappers/api_mappers.dart';
import '../models/service_model.dart';
import '../models/category_model.dart';
import '../models/time_slot_model.dart';
import 'service_repository.dart';

class ApiServiceRepository implements ServiceRepository {
  final ApiClient _client;
  final Map<String, ServiceModel> _cache = {};
  Map<String, dynamic>? _popularResponse;
  DateTime? _popularFetchedAt;
  Future<Map<String, dynamic>>? _popularInFlight;
  static const _discoverCacheTtl = Duration(seconds: 90);

  ApiServiceRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    AppLogger.state('ServiceRepository', 'getCategories');
    final response = await _client.get(
      ApiConstants.filters,
      forceRefresh: forceRefresh,
    );
    final data = response['data'] as Map<String, dynamic>?;
    final categories = ApiMappers.parseList(
      data?['categories'],
      (json) => ApiMappers.categoryFromJson(json),
    );
    if (categories.isNotEmpty) return categories;

    try {
      final catResponse = await _client.get(
        ApiConstants.categories,
        forceRefresh: forceRefresh,
      );
      final fromCategories = ApiMappers.parseList(
        catResponse['data'],
        (json) => ApiMappers.categoryFromJson(json),
      );
      if (fromCategories.isNotEmpty) return fromCategories;
    } catch (_) {}

    return categories;
  }

  @override
  Future<List<ServiceModel>> getAllServices() async {
    return searchServices('');
  }

  @override
  Future<List<ServiceModel>> getFeaturedServices({
    bool forceRefresh = false,
  }) async {
    AppLogger.state('ServiceRepository', 'getFeaturedServices');
    final response = await _getDiscoverPopular(forceRefresh: forceRefresh);
    final list = _parsePartners(response, featured: true);
    if (list.isEmpty) {
      final featured = await _client.get(
        ApiConstants.discoverFeatured,
        forceRefresh: forceRefresh,
      );
      return _parsePartners(featured, featured: true);
    }
    _cacheAll(list);
    return list;
  }

  @override
  Future<List<ServiceModel>> getTopRatedServices({
    bool forceRefresh = false,
  }) async {
    AppLogger.state('ServiceRepository', 'getTopRatedServices');
    final response = await _client.get(
      ApiConstants.discoverTopRated,
      forceRefresh: forceRefresh,
    );
    final list = _parsePartners(response, topRated: true);
    if (list.isEmpty) {
      final services = await _client.get(
        ApiConstants.services,
        queryParams: {'q': 'massage'},
      );
      return _parseServices(services);
    }
    _cacheAll(list);
    return list;
  }

  @override
  Future<List<ServiceModel>> getServicesByCategory(
    ServiceCategoryType category,
  ) async {
    AppLogger.state(
      'ServiceRepository',
      'getServicesByCategory',
      data: {'category': category.label},
    );
    final response = await _client.get(
      ApiConstants.services,
      queryParams: {'q': category.label.toLowerCase()},
    );
    final list = _parseServices(response);
    if (list.isNotEmpty) return list;
    final all = await searchServices('');
    return all.where((s) => s.category == category).toList();
  }

  @override
  Future<List<ServiceModel>> searchServices(
    String query, {
    bool forceRefresh = false,
  }) async {
    final q = query.trim();
    AppLogger.state('ServiceRepository', 'searchServices', data: {'query': q});

    if (q.isEmpty) {
      try {
        final response = await _client.get(ApiConstants.services);
        final list = _parseServices(response);
        if (list.isNotEmpty) {
          _cacheAll(list);
          return list;
        }
      } catch (e) {
        AppLogger.warning('All services load failed: $e');
      }
      try {
        final featured = await getFeaturedServices();
        if (featured.isNotEmpty) return featured;
      } catch (e) {
        AppLogger.warning('Featured fallback failed: $e');
      }
      return _cache.values.toList();
    }

    final results = <ServiceModel>[];
    final seen = <String>{};

    void addAll(List<ServiceModel> items) {
      for (final item in items) {
        if (seen.add(item.id)) results.add(item);
      }
    }

    try {
      final serviceResponse = await _client.get(
        ApiConstants.services,
        queryParams: {'q': q},
      );
      addAll(_parseServices(serviceResponse));
    } catch (_) {}

    try {
      final partnerResponse = await _client.get(
        ApiConstants.partners,
        queryParams: {'q': q},
      );
      addAll(_parsePartners(partnerResponse));
    } catch (_) {}

    if (results.isEmpty) {
      try {
        final suggest = await _client.get(
          ApiConstants.suggest,
          queryParams: {'q': q},
        );
        addAll(_parseSuggestPartners(suggest));
      } catch (_) {}
    }

    if (results.isNotEmpty) {
      _cacheAll(results);
      await _saveSearchHistory(q);
    }
    return results;
  }

  @override
  Future<ServiceModel?> getServiceForPartner(String partnerId) async {
    for (final service in _cache.values) {
      if (service.partnerId == partnerId) return service;
    }

    try {
      final response = await _client.get(ApiConstants.services);
      final services = _parseServices(response)
          .where((s) => s.partnerId == partnerId)
          .toList();
      if (services.isNotEmpty) {
        _cacheAll(services);
        return services.first;
      }
    } catch (e) {
      AppLogger.warning('Could not load services for partner $partnerId: $e');
    }

    try {
      final response = await _client.get(ApiConstants.partnerDetail(partnerId));
      final data = response['data'];
      if (data is Map) {
        return ApiMappers.partnerToService(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      AppLogger.warning('Could not load partner $partnerId: $e');
    }
    return null;
  }

  @override
  Future<ServiceModel?> getServiceById(String id) async {
    if (_cache.containsKey(id)) return _cache[id];
    try {
      final response = await _client.get('${ApiConstants.services}/$id');
      final data = response['data'];
      if (data is Map) {
        final service = ApiMappers.serviceFromApiJson(
          Map<String, dynamic>.from(data),
        );
        _cache[service.id] = service;
        return service;
      }
    } catch (_) {}
    final all = await searchServices('');
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<OfferBannerModel>> getBanners({bool forceRefresh = false}) async {
    AppLogger.state('ServiceRepository', 'getBanners');
    try {
      final response = await _getDiscoverPopular(forceRefresh: forceRefresh);
      final data = response['data'] as List?;
      if (data != null && data.isNotEmpty) {
        return List.generate(
          data.length,
          (i) => ApiMappers.bannerFromPartner(
            Map<String, dynamic>.from(data[i] as Map),
            i,
          ),
        );
      }
    } catch (e) {
      AppLogger.warning('Banner fetch failed: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> _getDiscoverPopular({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedAt = _popularFetchedAt;
      if (_popularResponse != null &&
          cachedAt != null &&
          DateTime.now().difference(cachedAt) < _discoverCacheTtl) {
        return _popularResponse!;
      }
    }
    if (_popularInFlight != null && !forceRefresh) return _popularInFlight!;
    _popularInFlight = _client
        .get(ApiConstants.discoverPopular, forceRefresh: forceRefresh)
        .then((response) {
          _popularResponse = response;
          _popularFetchedAt = DateTime.now();
          return response;
        })
        .whenComplete(() => _popularInFlight = null);
    return _popularInFlight!;
  }

  Future<List<ServiceModel>> getNearby({
    required double lat,
    required double lng,
  }) async {
    AppLogger.state(
      'ServiceRepository',
      'getNearby',
      data: {'lat': lat, 'lng': lng},
    );
    final response = await _client.get(
      ApiConstants.discoverNearby,
      queryParams: {'lat': lat.toString(), 'lng': lng.toString()},
    );
    return _parsePartners(response);
  }

  Future<List<String>> getSearchHistory() async {
    final response = await _client.get(ApiConstants.history, auth: true);
    final data = response['data'];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  Future<void> clearSearchHistory() async {
    await _client.delete(ApiConstants.history, auth: true);
  }

  List<ServiceModel> _parseServices(Map<String, dynamic> response) {
    return ApiMappers.parseList(
      response['data'],
      ApiMappers.serviceFromApiJson,
    );
  }

  List<ServiceModel> _parsePartners(
    Map<String, dynamic> response, {
    bool featured = false,
    bool topRated = false,
  }) {
    return ApiMappers.parseList(
      response['data'],
      (json) => ApiMappers.partnerToService(
        json,
        featured: featured,
        topRated: topRated,
      ),
    );
  }

  List<ServiceModel> _parseSuggestPartners(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>?;
    final partners = ApiMappers.parseList(
      data?['partners'],
      (json) => ApiMappers.partnerToService(json),
    );
    final services = ApiMappers.parseList(
      data?['services'],
      ApiMappers.serviceFromApiJson,
    );
    return [...services, ...partners];
  }

  void _cacheAll(List<ServiceModel> list) {
    for (final s in list) {
      _cache[s.id] = s;
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    try {
      await _client.post(
        ApiConstants.history,
        body: {'query': query},
        auth: true,
      );
    } catch (_) {
      // History save is optional when not logged in
    }
  }
}
