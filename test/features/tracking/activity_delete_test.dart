import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_gr4/core/constants/api_constants.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';
import 'package:proyecto_gr4/core/services/api_client.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service.dart';

class MockApiClient implements ApiClient {
  final Map<String, dynamic>? responseToReturn;
  final Exception? exceptionToThrow;
  String? lastMethod;
  String? lastUrl;

  MockApiClient({this.responseToReturn, this.exceptionToThrow});

  @override
  Future<dynamic> deleteJson(String endpoint, {bool authenticated = true, Object? body, Map<String, String>? headers}) async {
    lastMethod = 'DELETE';
    lastUrl = endpoint;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return responseToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ActivityService - deleteActivity Tests', () {
    test('1. Utiliza método DELETE y construye la URL correcta', () async {
      final mockClient = MockApiClient(responseToReturn: {});
      final service = ActivityService(apiClient: mockClient);

      await service.deleteActivity('act-123');

      expect(mockClient.lastMethod, 'DELETE');
      expect(mockClient.lastUrl, '${ApiConstants.activities}/act-123');
    });

    test('2. Envía Authorization Bearer (implícito por ApiClient) y respuesta 200 completa correctamente', () async {
      final mockClient = MockApiClient(responseToReturn: {'message': 'Deleted'});
      final service = ActivityService(apiClient: mockClient);

      await expectLater(service.deleteActivity('act-123'), completes);
    });

    test('3. Respuesta 204 completa correctamente', () async {
      final mockClient = MockApiClient(responseToReturn: null);
      final service = ActivityService(apiClient: mockClient);

      await expectLater(service.deleteActivity('act-123'), completes);
    });

    test('4. Error 401 se propaga', () async {
      final mockClient = MockApiClient(
        exceptionToThrow: ApiException(message: 'Unauthorized', statusCode: 401),
      );
      final service = ActivityService(apiClient: mockClient);

      await expectLater(
        service.deleteActivity('act-123'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('5. Error 403 se propaga', () async {
      final mockClient = MockApiClient(
        exceptionToThrow: ApiException(message: 'Forbidden', statusCode: 403),
      );
      final service = ActivityService(apiClient: mockClient);

      await expectLater(
        service.deleteActivity('act-123'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
      );
    });

    test('6. Error 404 se propaga', () async {
      final mockClient = MockApiClient(
        exceptionToThrow: ApiException(message: 'Not Found', statusCode: 404),
      );
      final service = ActivityService(apiClient: mockClient);

      await expectLater(
        service.deleteActivity('act-123'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('7. Error 500 se propaga y no oculta ApiException', () async {
      final mockClient = MockApiClient(
        exceptionToThrow: ApiException(message: 'Internal Error', statusCode: 500),
      );
      final service = ActivityService(apiClient: mockClient);

      await expectLater(
        service.deleteActivity('act-123'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('8. Id vacío no ejecuta solicitud', () async {
      final mockClient = MockApiClient();
      final service = ActivityService(apiClient: mockClient);

      await expectLater(
        service.deleteActivity(''),
        throwsA(isA<ArgumentError>()),
      );
      expect(mockClient.lastMethod, isNull);
    });
  });
}
