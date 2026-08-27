import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_constants.dart';
import '../mappers/api_mappers.dart';
import '../models/address_model.dart';
import 'address_repository.dart';

class ApiAddressRepository implements AddressRepository {
  final ApiClient _client;

  ApiAddressRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<AddressModel>> getAddresses() async {
    AppLogger.state('AddressRepository', 'getAddresses');
    try {
      final response = await _client.get(
        ApiConstants.usersMeAddresses,
        auth: true,
      );
      final list = ApiMappers.parseList(
        response['data'],
        ApiMappers.addressFromJson,
      );
      if (list.isNotEmpty) return list;
    } catch (_) {}

    final profile = await _client.get(ApiConstants.usersMe, auth: true);
    final data = profile['data'];
    if (data is Map && data['addresses'] is List) {
      return ApiMappers.parseList(
        data['addresses'],
        ApiMappers.addressFromJson,
      );
    }
    return [];
  }

  @override
  Future<AddressModel> addAddress(AddressModel address) async {
    AppLogger.state('AddressRepository', 'addAddress');
    final body = {
      'label': address.label,
      'line1': address.line1,
      if (address.line2.isNotEmpty) 'line2': address.line2,
      'city': address.city,
      'state': address.state,
      'pincode': address.pincode,
      'isDefault': address.isDefault,
    };
    final response = await _client.post(
      ApiConstants.usersMeAddresses,
      body: body,
      auth: true,
    );
    final data = response['data'];
    if (data is List && data.isNotEmpty) {
      return ApiMappers.addressFromJson(
        Map<String, dynamic>.from(data.last as Map),
      );
    }
    if (data is Map) {
      return ApiMappers.addressFromJson(Map<String, dynamic>.from(data));
    }
    return address;
  }

  @override
  Future<AddressModel> updateAddress(AddressModel address) async {
    AppLogger.state(
      'AddressRepository',
      'updateAddress',
      data: {'id': address.id},
    );
    final response = await _client.put(
      '${ApiConstants.usersMeAddresses}/${address.id}',
      body: {
        'label': address.label,
        'line1': address.line1,
        if (address.line2.isNotEmpty) 'line2': address.line2,
        'city': address.city,
        'state': address.state,
        'pincode': address.pincode,
        'isDefault': address.isDefault,
      },
      auth: true,
    );
    final data = response['data'];
    if (data is List) {
      for (final item in data) {
        if (item is Map && item['_id']?.toString() == address.id) {
          return ApiMappers.addressFromJson(Map<String, dynamic>.from(item));
        }
      }
    }
    if (data is Map) {
      return ApiMappers.addressFromJson(Map<String, dynamic>.from(data));
    }
    return address;
  }

  @override
  Future<void> deleteAddress(String id) async {
    AppLogger.state('AddressRepository', 'deleteAddress', data: {'id': id});
    await _client.delete('${ApiConstants.usersMeAddresses}/$id', auth: true);
  }

  @override
  Future<void> setDefaultAddress(String id) async {
    AppLogger.state('AddressRepository', 'setDefaultAddress', data: {'id': id});
    await _client.put(
      '${ApiConstants.usersMeAddresses}/$id/default',
      auth: true,
    );
  }
}
