// Standalone API test runner — hits live server (not blocked by flutter test).
// Run: dart run tool/api_test_runner.dart
import 'dart:io';
import 'package:glowvax/core/network/api_client.dart';
import 'package:glowvax/core/network/api_constants.dart';
import 'package:glowvax/core/storage/token_storage.dart';
import 'package:glowvax/data/repositories/api_auth_repository.dart';
import 'package:glowvax/data/repositories/api_service_repository.dart';
import 'package:glowvax/data/repositories/api_booking_repository.dart';
import 'package:glowvax/data/repositories/api_wallet_repository.dart';
import 'package:glowvax/data/repositories/api_membership_repository.dart';
import 'package:glowvax/data/repositories/api_notification_repository.dart';
import 'package:glowvax/data/repositories/api_address_repository.dart';
import 'package:glowvax/data/repositories/api_review_repository.dart';

const testPhone = '9999999999';
const testOtp = '123456';

void main() async {
  final storage = TokenStorage();
  final client = ApiClient(tokenStorage: storage);
  final auth = ApiAuthRepository(client: client, tokenStorage: storage);
  final services = ApiServiceRepository(client: client);
  final bookings = ApiBookingRepository(client: client);
  final wallet = ApiWalletRepository(client: client);
  final membership = ApiMembershipRepository(
    client: client,
    walletRepository: wallet,
  );
  final notifications = ApiNotificationRepository(client: client);
  final addresses = ApiAddressRepository(client: client);
  ApiReviewRepository(client: client);

  var passed = 0;
  var failed = 0;
  var skipped = 0;
  var authenticated = false;

  Future<void> run(
    String name,
    Future<void> Function() fn, {
    bool requiresAuth = false,
  }) async {
    if (requiresAuth && !authenticated) {
      skipped++;
      print('  $name ... ⏭️  SKIP (no auth)');
      return;
    }
    stdout.write('  $name ... ');
    try {
      await fn();
      passed++;
      print('✅ PASS');
    } catch (e) {
      failed++;
      print('❌ FAIL — $e');
    }
  }

  print('\n═══ Glowvax API Tests (Public + User) ═══');
  print('Base: ${ApiConstants.baseUrl}\n');

  print('── Auth ──');
  await run('POST /auth/send-otp', () async {
    if (!await auth.sendOtp(testPhone)) throw Exception('success=false');
  });

  await run('POST /auth/verify-otp', () async {
    try {
      final user = await auth.verifyOtp(testPhone, testOtp);
      if (user.phone != testPhone) throw Exception('phone mismatch');
      authenticated = true;
    } catch (e) {
      print('⚠️  verify-otp failed ($e) — user API tests will be skipped');
      rethrow;
    }
  });

  await run('POST /auth/forgot-password', () async {
    if (!await auth.forgotPassword('9876543210'))
      throw Exception('success=false');
  });

  print('\n── Public / Search ──');
  await run('GET /search/filters', () async {
    final r = await client.get(ApiConstants.filters);
    if (r['success'] != true) throw Exception('failed');
  });

  await run('GET /services?q=massage', () async {
    final r = await client.get(
      ApiConstants.services,
      queryParams: {'q': 'massage'},
    );
    if (r['success'] != true) throw Exception('failed');
  });

  await run('GET /search/suggest?q=sp', () async {
    final r = await client.get(ApiConstants.suggest, queryParams: {'q': 'sp'});
    if (r['success'] != true) throw Exception('failed');
  });

  await run('GET /partners?q=spa', () async {
    final r = await client.get(
      ApiConstants.partners,
      queryParams: {'q': 'spa'},
    );
    if (r['success'] != true) throw Exception('failed');
  });

  await run('GET /search/discover/popular', () async {
    final r = await client.get(ApiConstants.discoverPopular);
    if (r['success'] != true) throw Exception('failed');
  });

  await run('GET /search/discover/top-rated', () async {
    final r = await client.get(ApiConstants.discoverTopRated);
    if (r['success'] != true) throw Exception('failed');
  });

  await run('GET /search/discover/nearby', () async {
    final r = await client.get(
      ApiConstants.discoverNearby,
      queryParams: {'lat': '18.52', 'lng': '73.85'},
    );
    if (r['success'] != true) throw Exception('failed');
  });

  await run('GET /search/discover/new', () async {
    if ((await client.get(ApiConstants.discoverNew))['success'] != true)
      throw Exception('failed');
  });

  await run('GET /search/discover/featured', () async {
    if ((await client.get(ApiConstants.discoverFeatured))['success'] != true)
      throw Exception('failed');
  });

  await run('GET /settings/public', () async {
    if ((await client.get(ApiConstants.settingsPublic))['success'] != true)
      throw Exception('failed');
  });

  await run('GET /pages', () async {
    if ((await client.get(ApiConstants.pages))['success'] != true)
      throw Exception('failed');
  });

  await run('GET /membership/plans', () async {
    if ((await membership.getPlans()).isEmpty) {
      final r = await client.get(ApiConstants.membershipPlans);
      if (r['success'] != true) throw Exception('failed');
    }
  });

  await run('GET /reviews (public)', () async {
    final r = await client.get(ApiConstants.reviews);
    if (r['success'] != true) throw Exception('failed');
  });

  print('\n── User (authenticated) ──');
  await run('GET /users/me', () async {
    if ((await client.get(ApiConstants.usersMe, auth: true))['success'] != true)
      throw Exception('failed');
  }, requiresAuth: true);

  await run('GET /users/me/addresses', () async {
    await addresses.getAddresses();
  }, requiresAuth: true);

  await run('GET /bookings/my', () async {
    await bookings.getBookings();
  }, requiresAuth: true);

  await run('GET /bookings/upcoming', () async {
    await bookings.getUpcomingBookings();
  }, requiresAuth: true);

  await run('GET /bookings/history', () async {
    await bookings.getPastBookings();
  }, requiresAuth: true);

  await run('GET /wallet', () async {
    final balance = await wallet.getBalance();
    if (balance < 0) throw Exception('invalid balance');
  }, requiresAuth: true);

  await run('GET /wallet/transactions', () async {
    await wallet.getTransactions();
  }, requiresAuth: true);

  await run('GET /wallet/topup/options', () async {
    final r = await client.get(ApiConstants.walletTopupOptions, auth: true);
    if (r['success'] != true) throw Exception('failed');
  }, requiresAuth: true);

  await run('GET /notifications', () async {
    await notifications.getNotifications();
  }, requiresAuth: true);

  await run('GET /notifications/preferences', () async {
    final r = await client.get(
      ApiConstants.notificationsPreferences,
      auth: true,
    );
    if (r['success'] != true) throw Exception('failed');
  }, requiresAuth: true);

  await run('GET /membership/my', () async {
    final r = await client.get(ApiConstants.membershipMy, auth: true);
    if (r['success'] != true) throw Exception('failed');
  }, requiresAuth: true);

  await run('GET /membership/benefits', () async {
    final r = await client.get(ApiConstants.membershipBenefits, auth: true);
    if (r['success'] != true) throw Exception('failed');
  }, requiresAuth: true);

  await run('GET /favorites', () async {
    final r = await client.get(ApiConstants.favorites, auth: true);
    if (r['success'] != true) throw Exception('failed');
  }, requiresAuth: true);

  await run('POST /search/history', () async {
    await client.post(ApiConstants.history, body: {'query': 'spa'}, auth: true);
    await services.getSearchHistory();
  }, requiresAuth: true);

  await run('POST /auth/refresh', () async {
    final refresh = await storage.getRefreshToken();
    if (refresh == null) throw Exception('no refresh token');
    final r = await client.post(
      ApiConstants.refresh,
      body: {'refreshToken': refresh},
    );
    if (r['success'] != true) throw Exception('failed');
  }, requiresAuth: true);

  await run('POST /auth/logout', () async {
    await auth.logout();
    if (await storage.hasToken()) throw Exception('token still present');
  }, requiresAuth: true);

  client.dispose();

  print(
    '\n═══ Results: $passed passed, $failed failed, $skipped skipped ═══\n',
  );
  exit(failed > 0 ? 1 : 0);
}
