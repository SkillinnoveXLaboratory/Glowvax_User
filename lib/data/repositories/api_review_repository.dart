import '../../core/network/api_client.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/api_exception.dart';
import '../mappers/api_mappers.dart';
import '../models/review_model.dart';
import 'review_repository.dart';

class ApiReviewRepository implements ReviewRepository {
  final ApiClient _client;

  ApiReviewRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<ReviewModel>> getReviews({String? partnerId}) async {
    final path = partnerId != null
        ? ApiConstants.partnerReviews(partnerId)
        : ApiConstants.reviews;
    final response = await _client.get(path);
    return ApiMappers.parseList(response['data'], _reviewFromJson);
  }

  @override
  Future<List<ReviewModel>> getMyReviews() async {
    final response = await _client.get(ApiConstants.reviewsMy, auth: true);
    return ApiMappers.parseList(response['data'], _reviewFromJson);
  }

  @override
  Future<ReviewModel> addReview(ReviewModel review) async {
    final response = await _client.post(
      ApiConstants.reviews,
      body: {
        if (review.bookingId != null) 'bookingId': review.bookingId,
        'rating': review.rating.round(),
        'comment': review.comment,
      },
      auth: true,
    );
    if (response['success'] != true) {
      throw ApiException(
        response['message']?.toString() ?? 'Failed to submit review',
      );
    }
    final data = response['data'];
    if (data is Map) return _reviewFromJson(Map<String, dynamic>.from(data));
    return review;
  }

  @override
  Future<ReviewModel> updateReview(
    String id, {
    required double rating,
    required String comment,
  }) async {
    final response = await _client.put(
      ApiConstants.reviewDetail(id),
      body: {'rating': rating.round(), 'comment': comment},
      auth: true,
    );
    if (response['success'] != true) {
      throw ApiException(
        response['message']?.toString() ?? 'Failed to update review',
      );
    }
    final data = response['data'];
    if (data is Map) return _reviewFromJson(Map<String, dynamic>.from(data));
    throw ApiException('Invalid update response');
  }

  @override
  Future<void> deleteReview(String id) async {
    final response = await _client.delete(
      ApiConstants.reviewDetail(id),
      auth: true,
    );
    if (response['success'] != true) {
      throw ApiException(
        response['message']?.toString() ?? 'Failed to delete review',
      );
    }
  }

  @override
  Future<void> reportReview(String id, {required String reason}) async {
    final response = await _client.post(
      ApiConstants.reviewReport(id),
      body: {'reason': reason},
      auth: true,
    );
    if (response['success'] != true) {
      throw ApiException(
        response['message']?.toString() ?? 'Failed to report review',
      );
    }
  }

  ReviewModel _reviewFromJson(Map<String, dynamic> json) {
    final userJson = json['userId'];
    final partnerJson = json['partnerId'];
    final serviceJson = json['serviceId'];
    final userName = userJson is Map
        ? userJson['name']?.toString() ?? 'User'
        : (userJson != null ? 'You' : 'User');
    final serviceName = serviceJson is Map
        ? serviceJson['name']?.toString() ?? ''
        : json['serviceName']?.toString() ?? '';
    final partnerName = partnerJson is Map
        ? partnerJson['businessName']?.toString() ??
              partnerJson['name']?.toString() ??
              ''
        : '';

    return ReviewModel(
      id: json['_id']?.toString() ?? '',
      userId: userJson is Map
          ? userJson['_id']?.toString() ?? ''
          : userJson?.toString() ?? '',
      bookingId: json['bookingId']?.toString(),
      serviceId: serviceJson is Map
          ? serviceJson['_id']?.toString() ?? ''
          : partnerJson is Map
          ? partnerJson['_id']?.toString() ?? ''
          : partnerJson?.toString() ?? '',
      serviceName: serviceName.isNotEmpty ? serviceName : partnerName,
      partnerName: partnerName,
      userName: userName,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
