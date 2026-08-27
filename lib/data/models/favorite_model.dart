class FavoriteModel {
  final String id;
  final String partnerId;
  final String businessName;
  final double rating;
  final String? city;

  const FavoriteModel({
    required this.id,
    required this.partnerId,
    required this.businessName,
    this.rating = 0,
    this.city,
  });
}
