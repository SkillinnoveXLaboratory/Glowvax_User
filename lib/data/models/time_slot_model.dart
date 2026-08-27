class TimeSlotModel {
  final String id;
  final String label;
  final DateTime time;
  final bool isAvailable;

  const TimeSlotModel({
    required this.id,
    required this.label,
    required this.time,
    this.isAvailable = true,
  });
}

class OfferBannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String discountText;
  final String iconName;

  const OfferBannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.discountText,
    required this.iconName,
  });
}
