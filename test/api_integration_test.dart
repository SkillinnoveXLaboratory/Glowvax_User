import 'package:flutter_test/flutter_test.dart';
import 'package:glowvax/core/logging/app_logger.dart';
import 'package:glowvax/core/network/api_constants.dart';

/// Unit tests for logging & API config.
/// Live API tests: run `dart run tool/api_test_runner.dart`
void main() {
  test('API base URL is configured', () {
    expect(ApiConstants.baseUrl, contains('glow.digitalleadpro.com'));
    expect(ApiConstants.sendOtp, '/auth/send-otp');
    expect(ApiConstants.filters, '/search/filters');
    expect(ApiConstants.discoverPopular, '/search/discover/popular');
  });

  test('AppLogger methods do not throw', () {
    AppLogger.info('test info');
    AppLogger.apiRequest('GET', '/test');
    AppLogger.apiResponse(200, '/test', body: {'ok': true});
    AppLogger.navigation('PUSH', '/home', from: '/splash');
    AppLogger.buttonClick('Login', screen: '/login');
    AppLogger.state('TestProvider', 'load');
    AppLogger.success('done');
  });
}
