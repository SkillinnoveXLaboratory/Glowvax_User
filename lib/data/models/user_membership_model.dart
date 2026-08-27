class UserMembershipModel {
  final String id;
  final String planId;
  final String planName;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> benefits;
  final double discountPercent;

  const UserMembershipModel({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.benefits = const [],
    this.discountPercent = 0,
  });

  bool get isActive => status == 'active';
}
