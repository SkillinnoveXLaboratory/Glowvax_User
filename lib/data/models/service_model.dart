import 'category_model.dart';

class ServicePackageModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final int durationMinutes;
  final List<String> includes;

  const ServicePackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.durationMinutes,
    this.includes = const [],
  });

  double get discountPercent {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }
}

class ServiceModel {
  final String id;
  final String? partnerId;
  final String? categoryId;
  final String? categoryName;
  final String name;
  final String description;
  final ServiceCategoryType category;
  final double rating;
  final int reviewCount;
  final int bookingsCount;
  final String iconName;
  final List<String> tags;
  final List<ServicePackageModel> packages;
  final bool isFeatured;
  final bool isTopRated;

  const ServiceModel({
    required this.id,
    this.partnerId,
    this.categoryId,
    this.categoryName,
    required this.name,
    required this.description,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.bookingsCount,
    required this.iconName,
    this.tags = const [],
    required this.packages,
    this.isFeatured = false,
    this.isTopRated = false,
  });

  double get startingPrice {
    if (packages.isEmpty) return 0;
    return packages.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  int get minDuration {
    if (packages.isEmpty) return 0;
    return packages
        .map((p) => p.durationMinutes)
        .reduce((a, b) => a < b ? a : b);
  }
}
