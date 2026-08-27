class MembershipPlanModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationDays;
  final List<String> benefits;
  final bool isPopular;
  final double discountPercent;

  const MembershipPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    required this.benefits,
    this.isPopular = false,
    this.discountPercent = 0,
  });

  String get durationLabel {
    if (durationDays >= 365) {
      final years = (durationDays / 365).round();
      return years == 1 ? '1 year' : '$years years';
    }
    if (durationDays >= 30) {
      final months = (durationDays / 30).round();
      return months == 1 ? '1 month' : '$months months';
    }
    return durationDays == 1 ? '1 day' : '$durationDays days';
  }
}
