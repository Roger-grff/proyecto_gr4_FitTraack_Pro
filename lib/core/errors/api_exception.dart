class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseBody;

  const ApiException({
    required this.message,
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() => message;
}
