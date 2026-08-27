import '../models/review_model.dart';

abstract class ReviewRepository {
  Future<List<ReviewModel>> getReviews({String? partnerId});
  Future<List<ReviewModel>> getMyReviews();
  Future<ReviewModel> addReview(ReviewModel review);
  Future<ReviewModel> updateReview(
    String id, {
    required double rating,
    required String comment,
  });
  Future<void> deleteReview(String id);
  Future<void> reportReview(String id, {required String reason});
}
