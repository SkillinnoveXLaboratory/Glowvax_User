import 'package:flutter/material.dart';

import 'app_routes.dart';
import '../logging/app_logger.dart';
import '../../data/models/category_model.dart';
import '../../data/models/service_model.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/phone_login_screen.dart';
import '../../presentation/screens/auth/otp_verification_screen.dart';
import '../../presentation/screens/main/main_shell.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/category/category_services_screen.dart';
import '../../presentation/screens/service/service_detail_screen.dart';
import '../../presentation/screens/booking/booking_flow_screen.dart';
import '../../presentation/screens/booking/booking_confirmation_screen.dart';
import '../../presentation/screens/bookings/booking_detail_screen.dart';
import '../../presentation/screens/bookings/my_bookings_screen.dart';
import '../../presentation/screens/wallet/wallet_screen.dart';
import '../../presentation/screens/membership/membership_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';
import '../../presentation/screens/notifications/notification_preferences_screen.dart';
import '../../presentation/screens/reviews/reviews_screen.dart';
import '../../presentation/screens/reviews/write_review_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/addresses_screen.dart';
import '../../presentation/screens/profile/add_address_screen.dart';
import '../../presentation/screens/profile/favorites_screen.dart';
import '../../presentation/screens/profile/help_support_screen.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    AppLogger.navigation('GENERATE', settings.name ?? 'unknown');
    switch (settings.name) {
      case AppRoutes.splash:
        return _build(const SplashScreen(), settings);
      case AppRoutes.phoneLogin:
        return _build(const PhoneLoginScreen(), settings);
      case AppRoutes.otpVerification:
        return _build(const OtpVerificationScreen(), settings);
      case AppRoutes.main:
        final initialTab = settings.arguments is int
            ? settings.arguments as int
            : 0;
        return _build(MainShell(initialTab: initialTab), settings);
      case AppRoutes.search:
        return _build(const SearchScreen(), settings);
      case AppRoutes.categoryServices:
        final category = settings.arguments as CategoryModel;
        return _build(CategoryServicesScreen(category: category), settings);
      case AppRoutes.serviceDetail:
        return _build(const ServiceDetailScreen(), settings);
      case AppRoutes.bookingFlow:
        final args = settings.arguments as Map<String, dynamic>;
        return _build(
          BookingFlowScreen(
            service: args['service'] as ServiceModel,
            package: args['package'] as ServicePackageModel,
          ),
          settings,
        );
      case AppRoutes.bookingConfirmation:
        return _build(const BookingConfirmationScreen(), settings);
      case AppRoutes.bookingDetail:
        return _build(const BookingDetailScreen(), settings);
      case AppRoutes.bookings:
        return _build(const MyBookingsScreen(), settings);
      case AppRoutes.wallet:
        return _build(const WalletScreen(), settings);
      case AppRoutes.membership:
        return _build(const MembershipScreen(), settings);
      case AppRoutes.notifications:
        return _build(const NotificationsScreen(), settings);
      case AppRoutes.notificationPreferences:
        return _build(const NotificationPreferencesScreen(), settings);
      case AppRoutes.reviews:
        return _build(const ReviewsScreen(), settings);
      case AppRoutes.writeReview:
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => const WriteReviewScreen(),
        );
      case AppRoutes.editProfile:
        return _build(const EditProfileScreen(), settings);
      case AppRoutes.addresses:
        return _build(const AddressesScreen(), settings);
      case AppRoutes.addAddress:
        return _build(const AddAddressScreen(), settings);
      case AppRoutes.favorites:
        return _build(const FavoritesScreen(), settings);
      case AppRoutes.helpSupport:
        return _build(const HelpSupportScreen(), settings);
      default:
        return _build(const SplashScreen(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _build(
    Widget screen,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(settings: settings, builder: (_) => screen);
  }
}
