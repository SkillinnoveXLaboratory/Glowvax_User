import '../models/service_model.dart';
import '../models/category_model.dart';
import '../models/time_slot_model.dart';

abstract class ServiceRepository {
  Future<List<CategoryModel>> getCategories({bool forceRefresh = false});
  Future<List<ServiceModel>> getAllServices();
  Future<List<ServiceModel>> getFeaturedServices({bool forceRefresh = false});
  Future<List<ServiceModel>> getTopRatedServices({bool forceRefresh = false});
  Future<List<ServiceModel>> getServicesByCategory(
    ServiceCategoryType category,
  );
  Future<List<ServiceModel>> searchServices(
    String query, {
    bool forceRefresh = false,
  });
  Future<ServiceModel?> getServiceById(String id);
  Future<ServiceModel?> getServiceForPartner(String partnerId);
  Future<List<OfferBannerModel>> getBanners({bool forceRefresh = false});
}
