import '../../core/network/api_client.dart';
import '../../core/network/api_constants.dart';
import '../mappers/api_mappers.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences_model.dart';
import 'notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  final ApiClient _client;

  ApiNotificationRepository({ApiClient? client})
    : _client = client ?? ApiClient();

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await _client.get(ApiConstants.notifications, auth: true);
    return ApiMappers.parseList(
      response['data'],
      ApiMappers.notificationFromJson,
    );
  }

  @override
  Future<void> markAsRead(String id) async {
    await _client.put('${ApiConstants.notifications}/$id/read', auth: true);
  }

  @override
  Future<void> markAllAsRead() async {
    await _client.put(ApiConstants.notificationsReadAll, auth: true);
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _client.delete('${ApiConstants.notifications}/$id', auth: true);
  }

  @override
  Future<void> clearAll() async {
    await _client.delete(ApiConstants.notificationsClearAll, auth: true);
  }

  @override
  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  @override
  Future<NotificationPreferencesModel> getPreferences() async {
    final response = await _client.get(
      ApiConstants.notificationsPreferences,
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return NotificationPreferencesModel(
      bookingUpdates: data['bookingUpdates'] != false,
      promotions: data['promotions'] != false,
      walletAlerts: data['walletAlerts'] != false,
      reminders: data['reminders'] != false,
    );
  }

  @override
  Future<NotificationPreferencesModel> updatePreferences(
    NotificationPreferencesModel prefs,
  ) async {
    final response = await _client.put(
      ApiConstants.notificationsPreferences,
      body: prefs.toJson(),
      auth: true,
    );
    final data = response['data'] as Map<String, dynamic>? ?? prefs.toJson();
    return NotificationPreferencesModel(
      bookingUpdates: data['bookingUpdates'] != false,
      promotions: data['promotions'] != false,
      walletAlerts: data['walletAlerts'] != false,
      reminders: data['reminders'] != false,
    );
  }
}
