class NotificationPreferencesModel {
  final bool bookingUpdates;
  final bool promotions;
  final bool walletAlerts;
  final bool reminders;

  const NotificationPreferencesModel({
    this.bookingUpdates = true,
    this.promotions = true,
    this.walletAlerts = true,
    this.reminders = true,
  });

  NotificationPreferencesModel copyWith({
    bool? bookingUpdates,
    bool? promotions,
    bool? walletAlerts,
    bool? reminders,
  }) {
    return NotificationPreferencesModel(
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      promotions: promotions ?? this.promotions,
      walletAlerts: walletAlerts ?? this.walletAlerts,
      reminders: reminders ?? this.reminders,
    );
  }

  Map<String, dynamic> toJson() => {
    'bookingUpdates': bookingUpdates,
    'promotions': promotions,
    'walletAlerts': walletAlerts,
    'reminders': reminders,
  };
}
