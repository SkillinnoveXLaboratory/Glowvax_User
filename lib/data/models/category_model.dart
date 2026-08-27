enum ServiceCategoryType { parlour, spa, tattoo }

extension ServiceCategoryTypeX on ServiceCategoryType {
  String get label {
    switch (this) {
      case ServiceCategoryType.parlour:
        return 'Parlour';
      case ServiceCategoryType.spa:
        return 'Spa';
      case ServiceCategoryType.tattoo:
        return 'Tattoo';
    }
  }

  String get iconName {
    switch (this) {
      case ServiceCategoryType.parlour:
        return 'content_cut';
      case ServiceCategoryType.spa:
        return 'spa';
      case ServiceCategoryType.tattoo:
        return 'brush';
    }
  }
}

class CategoryModel {
  final String id;
  final String name;
  final ServiceCategoryType type;
  final String description;
  final int serviceCount;
  final String colorHex;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.serviceCount,
    required this.colorHex,
  });
}
