import '../models/notification_model.dart';
import '../models/notification_preferences_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> clearAll();
  Future<int> getUnreadCount();
  Future<NotificationPreferencesModel> getPreferences();
  Future<NotificationPreferencesModel> updatePreferences(
    NotificationPreferencesModel prefs,
  );
}
