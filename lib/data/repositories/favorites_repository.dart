import '../models/favorite_model.dart';

abstract class FavoritesRepository {
  Future<List<FavoriteModel>> getFavorites({bool forceRefresh = false});
  Future<void> addFavorite(String partnerId);
  Future<void> removeFavorite(String partnerId);
  Future<bool> isFavorited(String partnerId);
}
