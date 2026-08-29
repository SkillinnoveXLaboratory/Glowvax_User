import '../models/booking_model.dart';
import '../models/payment_models.dart';
import '../models/time_slot_model.dart';
import '../models/tip_record_model.dart';
import '../models/address_model.dart';
import '../models/wallet_transaction_model.dart';
import '../models/notification_model.dart';
import '../models/membership_plan_model.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';

class ApiMappers {
  ApiMappers._();

  static ServiceCategoryType mapCategorySlug(String? slug) {
    switch (slug?.toLowerCase()) {
      case 'parlour':
      case 'salon':
      case 'hair':
        return ServiceCategoryType.parlour;
      case 'tattoo':
        return ServiceCategoryType.tattoo;
      case 'spa':
      case 'wellness':
      case 'massage':
      default:
        return ServiceCategoryType.spa;
    }
  }

  static String iconForCategory(ServiceCategoryType type) {
    switch (type) {
      case ServiceCategoryType.parlour:
        return 'salon';
      case ServiceCategoryType.tattoo:
        return 'tattoo';
      case ServiceCategoryType.spa:
        return 'spa';
    }
  }

  static UserModel userFromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      referralCode: json['referralCode']?.toString(),
    );
  }

  static CategoryModel categoryFromJson(
    Map<String, dynamic> json, {
    int serviceCount = 0,
  }) {
    final slug =
        json['slug']?.toString() ??
        json['name']?.toString().toLowerCase() ??
        'spa';
    final type = mapCategorySlug(slug);
    return CategoryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Category',
      type: type,
      description: json['description']?.toString() ?? '',
      serviceCount: serviceCount,
      colorHex: '#D4AF37',
    );
  }

  static ServiceModel serviceFromApiJson(Map<String, dynamic> json) {
    final catJson = json['categoryId'];
    final partnerJson = json['partnerId'];
    final slug = catJson is Map ? catJson['slug']?.toString() : null;
    final category = mapCategorySlug(slug);
    final price = (json['price'] as num?)?.toDouble() ?? 0;
    final duration = (json['duration'] as num?)?.toInt() ?? 60;
    final rating = partnerJson is Map
        ? (partnerJson['rating'] as num?)?.toDouble() ?? 4.0
        : 4.0;

    return ServiceModel(
      id: json['_id']?.toString() ?? '',
      partnerId: partnerJson is Map
          ? partnerJson['_id']?.toString()
          : json['partnerId']?.toString(),
      categoryId: catJson is Map
          ? catJson['_id']?.toString() ?? catJson['id']?.toString()
          : null,
      categoryName: catJson is Map
          ? catJson['name']?.toString() ?? catJson['slug']?.toString()
          : null,
      name: json['name']?.toString() ?? 'Service',
      description: (json['tags'] as List?)?.join(', ') ?? '',
      category: category,
      rating: rating,
      reviewCount: 0,
      bookingsCount: 0,
      iconName: iconForCategory(category),
      tags: List<String>.from(json['tags'] ?? []),
      packages: [
        ServicePackageModel(
          id: '${json['_id']}_pkg',
          name: json['name']?.toString() ?? 'Standard',
          description: '',
          price: price,
          durationMinutes: duration,
        ),
      ],
      isFeatured: json['isFeatured'] == true,
      isTopRated: rating >= 4.5,
    );
  }

  static ServiceModel partnerToService(
    Map<String, dynamic> json, {
    bool featured = false,
    bool topRated = false,
  }) {
    final cats = json['categories'] as List?;
    final firstCat = cats?.isNotEmpty == true
        ? cats!.first as Map<String, dynamic>
        : null;
    final slug = firstCat?['slug']?.toString();
    final category = mapCategorySlug(slug);
    final rating = (json['rating'] as num?)?.toDouble() ?? 0;
    final address = json['address'] as Map<String, dynamic>?;

    return ServiceModel(
      id: json['_id']?.toString() ?? '',
      partnerId: json['_id']?.toString(),
      categoryId: firstCat?['_id']?.toString() ?? firstCat?['id']?.toString(),
      categoryName: firstCat?['name']?.toString() ?? slug,
      name: json['businessName']?.toString() ?? 'Partner',
      description:
          json['description']?.toString() ?? address?['city']?.toString() ?? '',
      category: category,
      rating: rating,
      reviewCount: (json['totalRatings'] as num?)?.toInt() ?? 0,
      bookingsCount: 0,
      iconName: iconForCategory(category),
      tags: firstCat != null ? [firstCat['name']?.toString() ?? ''] : [],
      packages: [
        ServicePackageModel(
          id: '${json['_id']}_visit',
          name: 'Book Visit',
          description: json['description']?.toString() ?? '',
          price: 0,
          durationMinutes: 60,
        ),
      ],
      isFeatured: featured || json['isFeatured'] == true,
      isTopRated: topRated || rating >= 4.5,
    );
  }

  static OfferBannerModel bannerFromPartner(
    Map<String, dynamic> json,
    int index,
  ) {
    final cats = json['categories'] as List?;
    final catName = cats?.isNotEmpty == true
        ? (cats!.first as Map)['name']?.toString()
        : 'Wellness';
    return OfferBannerModel(
      id: json['_id']?.toString() ?? 'banner_$index',
      title: json['businessName']?.toString() ?? 'Glowvax',
      subtitle:
          json['description']?.toString() ?? 'Book premium $catName services',
      discountText: 'BOOK NOW',
      iconName: 'spa',
    );
  }

  static List<T> parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) mapper,
  ) {
    if (data is! List) return [];
    final results = <T>[];
    for (final item in data) {
      if (item is! Map) continue;
      try {
        results.add(mapper(Map<String, dynamic>.from(item)));
      } catch (_) {
        // Skip malformed API rows instead of failing the whole list.
      }
    }
    return results;
  }

  static BookingStatus bookingStatusFromApi(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'confirmed':
        return BookingStatus.upcoming;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
      case 'rejected':
      case 'no_show':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.upcoming;
    }
  }

  static String bookingStatusLabelFromApi(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending Confirmation';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'no_show':
        return 'No Show';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Upcoming';
    }
  }

  static BookingModel bookingFromJson(Map<String, dynamic> json) {
    final serviceJson = json['serviceId'];
    final partnerJson = json['partnerId'];
    final dateStr = json['date']?.toString() ?? '';
    final timeSlot = json['timeSlot']?.toString() ?? '10:00';
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final timeParts = timeSlot.split(':');
    final hour = int.tryParse(timeParts.first) ?? 10;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    final scheduledAt = DateTime(date.year, date.month, date.day, hour, minute);

    final serviceName = serviceJson is Map
        ? serviceJson['name']?.toString() ?? 'Service'
        : 'Service';
    final serviceId = serviceJson is Map
        ? serviceJson['_id']?.toString() ?? ''
        : json['serviceId']?.toString() ?? '';
    final partnerId = partnerJson is Map
        ? partnerJson['_id']?.toString()
        : json['partnerId']?.toString();
    final partnerName = partnerJson is Map
        ? partnerJson['businessName']?.toString()
        : null;
    final staffJson = json['staffId'];
    final staffId = staffJson is Map
        ? staffJson['_id']?.toString() ?? staffJson['id']?.toString()
        : json['staffId']?.toString();
    final staffName = staffJson is Map ? staffJson['name']?.toString() : null;
    final address = partnerJson is Map
        ? partnerJson['address'] as Map<String, dynamic>?
        : null;
    final rawStatus = json['status']?.toString();
    final status = bookingStatusFromApi(rawStatus);
    final amount = (json['amount'] as num?)?.toDouble() ?? 0;
    final categoryJson = serviceJson is Map ? serviceJson['categoryId'] : null;
    final categorySlug = categoryJson is Map
        ? categoryJson['slug']?.toString()
        : null;
    final category = mapCategorySlug(categorySlug);
    final iconName = iconForCategory(category);

    return BookingModel(
      id: json['_id']?.toString() ?? '',
      serviceId: serviceId,
      partnerId: partnerId,
      serviceName: serviceName,
      packageName: serviceName,
      iconName: iconName,
      scheduledAt: scheduledAt,
      addressLabel: partnerName ?? 'Service location',
      addressLine: address != null
          ? '${address['line1'] ?? ''}, ${address['city'] ?? ''} - ${address['pincode'] ?? ''}'
          : '',
      amount: amount,
      status: status,
      statusText: bookingStatusLabelFromApi(rawStatus),
      professionalName: partnerName,
      staffId: staffId,
      staffName: staffName,
      canReview: status == BookingStatus.completed,
      paymentMethod: PaymentMethodX.fromApi(json['paymentMethod']?.toString()),
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      tipAmount: (json['tipAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  static TipRecordModel tipRecordFromJson(Map<String, dynamic> json) {
    return TipRecordModel(
      id: json['_id']?.toString() ?? '',
      transactionId:
          json['transactionId']?.toString() ?? json['_id']?.toString() ?? '',
      amount:
          (json['tipAmount'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble() ??
          0,
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ?? json['date']?.toString() ?? '',
          ) ??
          DateTime.now(),
      description: json['description']?.toString() ?? 'Tip received',
      type: json['type']?.toString() ?? 'direct_tip',
    );
  }

  static AddressModel addressFromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Address',
      line1: json['line1']?.toString() ?? '',
      line2: json['line2']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
    );
  }

  static List<TimeSlotModel> slotsFromApi(dynamic data, DateTime date) {
    if (data is! List) return [];
    final slots = <TimeSlotModel>[];
    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      String? timeStr;
      var available = true;
      if (item is String) {
        timeStr = item;
      } else if (item is Map) {
        timeStr =
            item['timeSlot']?.toString() ??
            item['time']?.toString() ??
            item['startTime']?.toString() ??
            item['slot']?.toString();
        available = item['isAvailable'] != false && item['available'] != false;
      }
      if (timeStr == null || !timeStr.contains(':')) continue;
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final time = DateTime(date.year, date.month, date.day, hour, minute);
      slots.add(
        TimeSlotModel(
          id: 'slot_${i}_$timeStr',
          label: _formatTimeLabel(hour, minute),
          time: time,
          isAvailable: available,
        ),
      );
    }
    return slots;
  }

  static String _formatTimeLabel(int hour, int minute) {
    final mm = minute.toString().padLeft(2, '0');
    if (hour < 12) return '${hour == 0 ? 12 : hour}:$mm AM';
    if (hour == 12) return '12:$mm PM';
    return '${hour - 12}:$mm PM';
  }

  static WalletTransactionModel walletTransactionFromJson(
    Map<String, dynamic> json,
  ) {
    final typeStr = json['type']?.toString().toLowerCase();
    return WalletTransactionModel(
      id: json['_id']?.toString() ?? '',
      title: typeStr == 'credit' ? 'Credit' : 'Debit',
      description: json['description']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: typeStr == 'credit'
          ? TransactionType.credit
          : TransactionType.debit,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static NotificationType notificationTypeFromApi(String? type) {
    switch (type?.toLowerCase()) {
      case 'booking':
        return NotificationType.booking;
      case 'offer':
      case 'promotion':
        return NotificationType.offer;
      case 'wallet':
        return NotificationType.wallet;
      case 'membership':
        return NotificationType.membership;
      default:
        return NotificationType.general;
    }
  }

  static NotificationModel notificationFromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: notificationTypeFromApi(json['type']?.toString()),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] == true,
    );
  }

  static MembershipPlanModel membershipPlanFromJson(Map<String, dynamic> json) {
    final benefits =
        (json['benefits'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final durationDays = (json['durationDays'] as num?)?.toInt() ?? 30;
    return MembershipPlanModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Plan',
      description: benefits.join(' • '),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationDays: durationDays,
      benefits: benefits,
      isPopular: json['sortOrder'] == 1,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}
