class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://glow.digitalleadpro.com/api/v1';

  // Auth — live server uses /auth/* prefix
  static const String sendOtp = '/auth/send-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String changePassword = '/auth/change-password';

  // Search & discover — live server uses /search/* prefix
  static const String partners = '/partners';
  static const String services = '/services';
  static const String suggest = '/search/suggest';
  static const String filters = '/search/filters';
  static const String discoverNearby = '/search/discover/nearby';
  static const String discoverPopular = '/search/discover/popular';
  static const String discoverTopRated = '/search/discover/top-rated';
  static const String discoverNew = '/search/discover/new';
  static const String discoverFeatured = '/search/discover/featured';
  static const String history = '/search/history';

  // Social auth
  static const String googleAuth = '/auth/social/google';
  static const String facebookAuth = '/auth/social/facebook';

  // General
  static const String categories = '/categories';
  static const String pages = '/cms/pages';
  static const String settingsPublic = '/settings/public';
  static const String promoValidate = '/promo/validate';
  static const String referralMy = '/referral/my';

  // User — bookings
  static const String bookings = '/bookings';
  static const String bookingsMy = '/bookings/my';
  static const String bookingsUpcoming = '/bookings/upcoming';
  static const String bookingsHistory = '/bookings/history';

  // User — reviews
  static const String reviews = '/reviews';
  static const String reviewsMy = '/reviews/my';
  static String reviewDetail(String id) => '/reviews/$id';
  static String reviewReply(String id) => '/reviews/$id/reply';
  static String reviewReport(String id) => '/reviews/$id/report';
  static String partnerReviews(String partnerId) =>
      '/reviews/partner/$partnerId';
  static String partnerReviewSummary(String partnerId) =>
      '/reviews/partner/$partnerId/summary';

  // User — membership
  static const String membershipPlans = '/membership/plans';
  static const String membershipMy = '/membership/my';
  static const String membershipSubscribe = '/membership/subscribe';
  static const String membershipSubscribeVerify =
      '/membership/subscribe/verify';
  static const String membershipBenefits = '/membership/benefits';
  static const String membershipHistory = '/membership/history';
  static const String membershipCancel = '/membership/my/cancel';

  // User — notifications
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationsPreferences = '/notifications/preferences';
  static const String notificationsClearAll = '/notifications/clear-all';

  // User — wallet
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletTopupOptions = '/wallet/topup/options';
  static const String walletTopupInitiate = '/wallet/topup/initiate';
  static const String walletTopupVerify = '/wallet/topup/verify';
  static const String walletPay = '/wallet/pay';
  static String bookingCheckout(String id) => '/bookings/$id/checkout';
  static String bookingCheckoutVerify(String id) =>
      '/bookings/$id/checkout/verify';
  static String bookingRefund(String id) => '/bookings/$id/refund';
  static const String walletPaymentMethods = '/wallet/payment/methods';

  // User — profile & addresses
  static const String usersMe = '/users/me';
  static const String usersMeAddresses = '/users/me/addresses';

  // User — favorites
  static const String favorites = '/favorites';

  static String partnerSlots(String partnerId) => '/partners/$partnerId/slots';
  static String partnerDetail(String partnerId) => '/partners/$partnerId';
  static String partnerTips(String partnerId) => '/partners/$partnerId/tips';

  static const Duration connectTimeout = Duration(seconds: 30);
}
