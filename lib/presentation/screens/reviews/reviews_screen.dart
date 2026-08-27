import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/review_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/reviews/review_card.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReviewModel> _allReviews = [];
  List<ReviewModel> _myReviews = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _composeRequested = false;
  String? _error;
  String? _partnerId;
  bool _openComposeOnLoad = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _partnerId = args;
      } else if (args is Map) {
        _partnerId = args['partnerId']?.toString();
        _openComposeOnLoad = args['mode'] == 'compose';
      }
      _loadReviews();
    });
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() {
      _isLoading = !_hasLoaded;
      _error = null;
    });
    try {
      final repo = context.read<ReviewRepository>();
      final results = await Future.wait([
        repo.getReviews(partnerId: _partnerId),
        repo.getMyReviews(),
      ]);
      if (!mounted) return;
      setState(() {
        _allReviews = results[0];
        _myReviews = results[1];
        _isLoading = false;
        _hasLoaded = true;
      });
      if (_openComposeOnLoad && !_composeRequested) {
        _composeRequested = true;
        _tabController.animateTo(1);
        await _openWriteReviewPicker();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _hasLoaded = true;
      });
    }
  }

  Future<void> _openWriteReviewPicker() async {
    final bookingProvider = context.read<BookingProvider>();
    if (!bookingProvider.hasLoaded) {
      await bookingProvider.loadBookings(forceRefresh: true);
    }
    if (!mounted) return;

    final reviewable = bookingProvider.pastBookings
        .where(
          (b) =>
              b.canReview && (_partnerId == null || b.partnerId == _partnerId),
        )
        .toList();
    if (reviewable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No completed bookings are ready for review yet.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<BookingModel>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a booking to review',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimaryOf(sheetContext),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Only completed bookings can be reviewed.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryOf(sheetContext),
                ),
              ),
              const SizedBox(height: 12),
              ...reviewable.map(
                (booking) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.spa_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    booking.serviceName,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimaryOf(sheetContext),
                    ),
                  ),
                  subtitle: Text(
                    '${booking.partnerDisplayName} - ${Formatters.dateTime(booking.scheduledAt)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryOf(sheetContext),
                    ),
                  ),
                  trailing: Text(
                    booking.bookingCode,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: () => Navigator.pop(sheetContext, booking),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || !mounted) return;
    final wrote = await Navigator.pushNamed(
      context,
      AppRoutes.writeReview,
      arguments: {
        'bookingId': selected.id,
        'serviceName': selected.serviceName,
        'partnerName': selected.partnerDisplayName,
      },
    );
    if (wrote == true) {
      _loadReviews();
    }
  }

  Future<void> _editReview(ReviewModel review) async {
    var rating = review.rating;
    final commentCtrl = TextEditingController(text: review.comment);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      onPressed: () =>
                          setDialogState(() => rating = index + 1.0),
                      icon: Icon(
                        index < rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: commentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Your review'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    try {
      await context.read<ReviewRepository>().updateReview(
        review.id,
        rating: rating,
        comment: commentCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review updated'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadReviews();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Failed to update review';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deleteReview(ReviewModel review) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ReviewRepository>().deleteReview(review.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review deleted'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadReviews();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Failed to delete review';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _reportReview(ReviewModel review) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report Review'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Why are you reporting this review?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    try {
      await context.read<ReviewRepository>().reportReview(
        review.id,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review reported'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Failed to report review';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _partnerId != null ? 'Partner Reviews' : AppStrings.reviews;
    final myIds = _myReviews.map((review) => review.id).toSet();
    final currentUserId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Reviews'),
            Tab(text: 'My Reviews'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReviews),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openWriteReviewPicker,
        backgroundColor: AppColors.primary,
        icon: const Icon(
          Icons.rate_review_outlined,
          color: AppColors.textOnGold,
        ),
        label: const Text(
          'Write Review',
          style: TextStyle(color: AppColors.textOnGold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Retry',
                      onPressed: _loadReviews,
                      width: 160,
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadReviews,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ReviewList(
                    reviews: _allReviews,
                    emptyText: _partnerId != null
                        ? 'No reviews for this partner yet'
                        : 'No reviews yet',
                    showPartnerName: _partnerId == null,
                    canReport: (review) =>
                        !myIds.contains(review.id) &&
                        (currentUserId == null ||
                            review.userId != currentUserId),
                    onReport: _reportReview,
                  ),
                  _ReviewList(
                    reviews: _myReviews,
                    emptyText: 'You have not written any reviews',
                    showPartnerName: true,
                    onWrite: _openWriteReviewPicker,
                    canEdit: (_) => true,
                    canDelete: (_) => true,
                    onEdit: _editReview,
                    onDelete: _deleteReview,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  final List<ReviewModel> reviews;
  final String emptyText;
  final bool showPartnerName;
  final VoidCallback? onWrite;
  final bool Function(ReviewModel review)? canEdit;
  final bool Function(ReviewModel review)? canDelete;
  final bool Function(ReviewModel review)? canReport;
  final void Function(ReviewModel review)? onEdit;
  final void Function(ReviewModel review)? onDelete;
  final void Function(ReviewModel review)? onReport;

  const _ReviewList({
    required this.reviews,
    required this.emptyText,
    this.showPartnerName = false,
    this.onWrite,
    this.canEdit,
    this.canDelete,
    this.canReport,
    this.onEdit,
    this.onDelete,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              emptyText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
          if (onWrite != null) ...[
            const SizedBox(height: 20),
            Center(
              child: AppButton(
                label: 'Write a Review',
                onPressed: onWrite,
                width: 200,
              ),
            ),
          ],
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return ReviewCard(
          review: review,
          showServiceName: true,
          showPartnerName: showPartnerName,
          showEdit: canEdit?.call(review) ?? false,
          showDelete: canDelete?.call(review) ?? false,
          showReport: canReport?.call(review) ?? false,
          onEdit: onEdit == null ? null : () => onEdit!(review),
          onDelete: onDelete == null ? null : () => onDelete!(review),
          onReport: onReport == null ? null : () => onReport!(review),
        );
      },
    );
  }
}
