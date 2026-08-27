import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/favorite_model.dart';
import '../../data/repositories/favorites_repository.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repository;

  FavoritesProvider(this._repository);

  List<FavoriteModel> _favorites = [];
  final Set<String> _favoritedIds = {};
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;
  Future<void>? _loadFuture;

  List<FavoriteModel> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  bool isFavorited(String partnerId) => _favoritedIds.contains(partnerId);

  Future<void> ensureLoaded() {
    if (_hasLoaded) return Future.value();
    return _loadFuture ??= _loadFavoritesInternal();
  }

  Future<void> loadFavorites({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _hasLoaded = false;
      _loadFuture = null;
    }
    await _loadFavoritesInternal(forceRefresh: forceRefresh);
  }

  Future<void> _loadFavoritesInternal({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _favorites = await _repository.getFavorites(forceRefresh: forceRefresh);
      _favoritedIds
        ..clear()
        ..addAll(_favorites.map((f) => f.partnerId));
      _hasLoaded = true;
    } catch (e) {
      _error = e is ApiException ? e.message : 'Could not load favorites';
    } finally {
      _isLoading = false;
      _loadFuture = null;
      notifyListeners();
    }
  }

  Future<void> checkFavorite(String partnerId) async {
    await ensureLoaded();
    notifyListeners();
  }

  Future<void> toggleFavorite(String partnerId) async {
    await ensureLoaded();
    if (_favoritedIds.contains(partnerId)) {
      await _repository.removeFavorite(partnerId);
      _favoritedIds.remove(partnerId);
      _favorites.removeWhere((f) => f.partnerId == partnerId);
    } else {
      await _repository.addFavorite(partnerId);
      _favoritedIds.add(partnerId);
    }
    notifyListeners();
  }

  void clear() {
    _favorites = [];
    _favoritedIds.clear();
    _hasLoaded = false;
    _error = null;
    _loadFuture = null;
    notifyListeners();
  }
}
