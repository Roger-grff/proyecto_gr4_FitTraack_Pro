import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_gr4/features/stats/data/stats_service.dart';
import 'package:proyecto_gr4/core/services/api_client.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';
import 'package:http/http.dart' as http;

class MockApiClient implements ApiClient {
  @override
  final http.Client client = http.Client();
  @override
  final TokenReader tokenReader = () async => "token";
  @override
  final Duration timeout = const Duration(seconds: 15);

  Map<String, dynamic>? mockGetResponse;
  Exception? mockException;

  @override
  Future deleteJson(String url, {Object? body, bool authenticated = true, Map<String, String>? headers}) async => null;

  @override
  Future getJson(String url, {bool authenticated = true, Map<String, String>? headers}) async {
    if (mockException != null) throw mockException!;
    return mockGetResponse;
  }

  @override
  Future patchJson(String url, {Object? body, bool authenticated = true, Map<String, String>? headers}) async => null;

  @override
  Future postJson(String url, {Object? body, bool authenticated = true, Map<String, String>? headers}) async => null;

  @override
  Future postMultipart(String url, {required String filePath, required String fileField, bool authenticated = true, Map<String, String>? fields}) async => null;
}

void main() {
  late MockApiClient mockApiClient;
  late StatsService service;

  setUp(() {
    mockApiClient = MockApiClient();
    service = StatsService(apiClient: mockApiClient);
  });

  group('StatsService Tests', () {
    final validStatsJson = {
      "stats": <String, dynamic>{
        "totalDistance": 10.0,
        "totalActivities": 2,
        "oms": <String, dynamic>{},
        "balanceCalorico": <String, dynamic>{}
      }
    };

    test('1. GET stats correcto', () async {
      mockApiClient.mockGetResponse = validStatsJson;
      final stats = await service.getMyStats();
      expect(stats.totalDistance, 10.0);
      expect(stats.totalActivities, 2);
    });

    test('2. GET stats con error de formato', () async {
      mockApiClient.mockGetResponse = {"invalid": "data"};
      expect(() => service.getMyStats(), throwsA(isA<ApiException>()));
    });

    test('3. Propaga ApiException', () async {
      mockApiClient.mockException = const ApiException(message: "No autorizado", statusCode: 401);
      expect(() => service.getMyStats(), throwsA(isA<ApiException>()));
    });
  });
}
