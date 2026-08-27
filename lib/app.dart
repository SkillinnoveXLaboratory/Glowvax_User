import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/payment/razorpay_payment_service.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_generator.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/logging/navigation_observer.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/api_auth_repository.dart';
import 'data/repositories/service_repository.dart';
import 'data/repositories/api_service_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/api_booking_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'data/repositories/api_wallet_repository.dart';
import 'data/repositories/membership_repository.dart';
import 'data/repositories/api_membership_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/api_notification_repository.dart';
import 'data/repositories/address_repository.dart';
import 'data/repositories/api_address_repository.dart';
import 'data/repositories/review_repository.dart';
import 'data/repositories/api_review_repository.dart';
import 'data/repositories/favorites_repository.dart';
import 'data/repositories/api_favorites_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/home_provider.dart';
import 'presentation/providers/search_provider.dart';
import 'presentation/providers/booking_provider.dart';
import 'presentation/providers/wallet_provider.dart';
import 'presentation/providers/membership_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/favorites_provider.dart';
import 'presentation/providers/theme_provider.dart';

class GlowvaxApp extends StatelessWidget {
  const GlowvaxApp({
    super.key,
    required this.tokenStorage,
    required this.themeProvider,
  });

  final TokenStorage tokenStorage;
  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final navigatorObserver = AppNavigatorObserver();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        Provider<ApiClient>(create: (_) => apiClient),
        Provider<TokenStorage>(create: (_) => tokenStorage),
        Provider<AuthRepository>(
          create: (_) =>
              ApiAuthRepository(client: apiClient, tokenStorage: tokenStorage),
        ),
        Provider<ServiceRepository>(
          create: (_) => ApiServiceRepository(client: apiClient),
        ),
        Provider<BookingRepository>(
          create: (_) => ApiBookingRepository(client: apiClient),
        ),
        Provider<WalletRepository>(
          create: (_) => ApiWalletRepository(client: apiClient),
        ),
        Provider<MembershipRepository>(
          create: (ctx) => ApiMembershipRepository(
            client: apiClient,
            walletRepository: ctx.read<WalletRepository>(),
          ),
        ),
        Provider<NotificationRepository>(
          create: (_) => ApiNotificationRepository(client: apiClient),
        ),
        Provider<AddressRepository>(
          create: (_) => ApiAddressRepository(client: apiClient),
        ),
        Provider<ReviewRepository>(
          create: (_) => ApiReviewRepository(client: apiClient),
        ),
        Provider<FavoritesRepository>(
          create: (_) => ApiFavoritesRepository(client: apiClient),
        ),
        Provider<RazorpayPaymentService>(
          create: (_) => RazorpayPaymentService(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(ctx.read<AuthRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => HomeProvider(ctx.read<ServiceRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SearchProvider(ctx.read<ServiceRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => BookingProvider(
            ctx.read<BookingRepository>(),
            ctx.read<AddressRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => WalletProvider(ctx.read<WalletRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => MembershipProvider(
            ctx.read<MembershipRepository>(),
            ctx.read<WalletRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              NotificationProvider(ctx.read<NotificationRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => FavoritesProvider(ctx.read<FavoritesRepository>()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            key: ValueKey('app-theme-${theme.mode.name}'),
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.mode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: RouteGenerator.generateRoute,
            navigatorObservers: [navigatorObserver],
            builder: (context, child) {
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
