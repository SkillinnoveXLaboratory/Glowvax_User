class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String serviceId;
  final String serviceName;
  final String partnerName;
  final String? bookingId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.serviceId,
    required this.serviceName,
    this.partnerName = '',
    this.bookingId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}
