// Tests: review edit/delete/report, partner reply, staff schedule edit
// Run: dart run tool/review_schedule_api_test.dart
import 'dart:io';
import 'package:glowvax/core/network/api_client.dart';
import 'package:glowvax/core/network/api_constants.dart';
import 'package:glowvax/core/storage/token_storage.dart';
import 'package:glowvax/data/repositories/api_auth_repository.dart';

const userPhone = '9876543100';
const testOtp = '123456';

Future<void> main() async {
  var passed = 0;
  var failed = 0;

  Future<void> run(String name, Future<void> Function() fn) async {
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

  print('\n═══ Review + Schedule API Tests ═══');
  print('Base: ${ApiConstants.baseUrl}\n');

  // ── User auth ──
  final userStorage = TokenStorage();
  final userClient = ApiClient(tokenStorage: userStorage);
  final userAuth = ApiAuthRepository(client: userClient, tokenStorage: userStorage);

  String? reviewId;

  print('── User: auth ──');
  await run('User send-otp', () async {
    if (!await userAuth.sendOtp(userPhone)) throw Exception('send-otp failed');
  });
  await run('User verify-otp', () async {
    final user = await userAuth.verifyOtp(userPhone, testOtp);
    if (user.phone != userPhone) throw Exception('phone mismatch');
  });

  print('\n── User: reviews ──');
  await run('GET /reviews/my', () async {
    final r = await userClient.get(ApiConstants.reviewsMy, auth: true);
    if (r['success'] != true) throw Exception(r['message']);
    final data = r['data'] as List?;
    if (data != null && data.isNotEmpty) {
      reviewId = (data.first as Map)['_id']?.toString();
    }
  });

  await run('POST /reviews (create if needed)', () async {
    if (reviewId != null) return;
    final bookings = await userClient.get(ApiConstants.bookingsHistory, auth: true);
    final list = bookings['data'] as List? ?? [];
    String? bookingId;
    for (final b in list) {
      final m = b as Map;
      if (m['status'] == 'completed') {
        bookingId = m['_id']?.toString();
        break;
      }
    }
    if (bookingId == null) {
      throw Exception('No completed booking to create review — skip create');
    }
    final r = await userClient.post(
      ApiConstants.reviews,
      body: {'bookingId': bookingId, 'rating': 4, 'comment': 'API test review'},
      auth: true,
    );
    if (r['success'] != true) throw Exception(r['message']);
    reviewId = (r['data'] as Map?)?['_id']?.toString();
    if (reviewId == null) throw Exception('no review id returned');
  });

  await run('PUT /reviews/{id} (edit)', () async {
    if (reviewId == null) throw Exception('no review id');
    final r = await userClient.put(
      ApiConstants.reviewDetail(reviewId!),
      body: {'comment': 'Updated via API test', 'rating': 5},
      auth: true,
    );
    if (r['success'] != true) throw Exception(r['message']);
  });

  await run('POST /reviews/{id}/report', () async {
    if (reviewId == null) throw Exception('no review id');
    // Report a different review if possible (can't report own in some backends)
    final all = await userClient.get(ApiConstants.reviews, auth: true);
    final data = all['data'] as List? ?? [];
    String? targetId;
    for (final item in data) {
      final id = (item as Map)['_id']?.toString();
      if (id != null && id != reviewId) {
        targetId = id;
        break;
      }
    }
    targetId ??= reviewId;
    final r = await userClient.post(
      ApiConstants.reviewReport(targetId!),
      body: {'reason': 'Inappropriate content (API test)'},
      auth: true,
    );
    if (r['success'] != true) throw Exception(r['message']);
  });

  // Keep delete last among user review tests
  await run('DELETE /reviews/{id}', () async {
    if (reviewId == null) throw Exception('no review id');
    final r = await userClient.delete(ApiConstants.reviewDetail(reviewId!), auth: true);
    if (r['success'] != true) throw Exception(r['message']);
    reviewId = null;
  });

  userClient.dispose();
  print('\n  (Partner reply + staff schedule: run glowvax_partner/tool/review_schedule_api_test.dart)');
  print('\n═══ Results: $passed passed, $failed failed ═══\n');
  exit(failed > 0 ? 1 : 0);
}
