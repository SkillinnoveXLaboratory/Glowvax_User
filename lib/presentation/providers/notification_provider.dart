import 'package:flutter/foundation.dart';

import '../../data/models/notification_model.dart';
import '../../data/models/notification_preferences_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider(this._repository);

  List<NotificationModel> _notifications = [];
  NotificationPreferencesModel _preferences =
      const NotificationPreferencesModel();
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _hasLoaded = false;

  List<NotificationModel> get notifications => _notifications;
  NotificationPreferencesModel get preferences => _preferences;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  Future<void> loadNotifications() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await _repository.getNotifications();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      // Non-fatal — home can load without notification badge
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  Future<void> loadPreferences() async {
    _preferences = await _repository.getPreferences();
    notifyListeners();
  }

  Future<void> updatePreferences(NotificationPreferencesModel prefs) async {
    _preferences = await _repository.updatePreferences(prefs);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    await loadNotifications();
  }

  Future<void> deleteNotification(String id) async {
    await _repository.deleteNotification(id);
    await loadNotifications();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    await loadNotifications();
  }
}
