import '../../core/network/api_client.dart';
import '../../core/network/api_constants.dart';
import '../models/favorite_model.dart';
import 'favorites_repository.dart';

class ApiFavoritesRepository implements FavoritesRepository {
  final ApiClient _client;

  ApiFavoritesRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<FavoriteModel>> getFavorites({bool forceRefresh = false}) async {
    final response = await _client.get(
      ApiConstants.favorites,
      auth: true,
      forceRefresh: forceRefresh,
    );
    final data = response['data'];
    if (data is! List) return [];
    return data
        .map((e) => _fromJson(Map<String, dynamic>.from(e as Map)))
        .where((f) => f.partnerId.isNotEmpty)
        .toList();
  }

  @override
  Future<void> addFavorite(String partnerId) async {
    await _client.post('${ApiConstants.favorites}/$partnerId', auth: true);
  }

  @override
  Future<void> removeFavorite(String partnerId) async {
    await _client.delete('${ApiConstants.favorites}/$partnerId', auth: true);
  }

  @override
  Future<bool> isFavorited(String partnerId) async {
    try {
      final response = await _client.get(
        '${ApiConstants.favorites}/$partnerId/check',
        auth: true,
      );
      final data = response['data'] as Map<String, dynamic>?;
      return data?['isFavorited'] == true;
    } catch (_) {
      return false;
    }
  }

  FavoriteModel _fromJson(Map<String, dynamic> json) {
    final partner = json['partnerId'] ?? json['partner'];
    if (partner is Map) {
      final address = partner['address'] as Map<String, dynamic>?;
      return FavoriteModel(
        id: json['_id']?.toString() ?? partner['_id']?.toString() ?? '',
        partnerId: partner['_id']?.toString() ?? '',
        businessName: partner['businessName']?.toString() ?? 'Partner',
        rating: (partner['rating'] as num?)?.toDouble() ?? 0,
        city: address?['city']?.toString(),
      );
    }

    final partnerId = partner?.toString() ?? json['partner']?.toString() ?? '';
    return FavoriteModel(
      id: json['_id']?.toString() ?? partnerId,
      partnerId: partnerId,
      businessName: json['businessName']?.toString() ?? 'Saved partner',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      city: json['city']?.toString(),
    );
  }
}
