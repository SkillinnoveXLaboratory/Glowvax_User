class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic raw;

  const ApiException(this.message, {this.statusCode, this.code, this.raw});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
