import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:proyecto_gr4/core/constants/api_constants.dart';
import 'package:proyecto_gr4/core/services/api_client.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service.dart';

import 'package:proyecto_gr4/features/tracking/domain/activity_session.dart';
import 'package:proyecto_gr4/features/tracking/domain/location_point.dart';
import 'package:proyecto_gr4/features/tracking/domain/tracking_stats.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';
import 'dart:convert';

void main() {
  group('ActivityService Tests', () {
    const testToken = 'token';
    Future<String?> mockTokenReader() async => testToken;

    ActivityService createService(http.Client mockHttpClient) {
      final apiClient = ApiClient(
        client: mockHttpClient,
        tokenReader: mockTokenReader,
      );
      return ActivityService(apiClient: apiClient);
    }

    final dummySession = ActivitySession(
      id: 'local_id',
      title: 'Run',
      startTime: DateTime(2026, 7, 16, 8, 0, 0),
      endTime: DateTime(2026, 7, 16, 8, 30, 0),
      routePoints: [
        LocationPoint(latitude: 1, longitude: 1, timestamp: DateTime(2026, 7, 16, 8, 0, 0))
      ],
      stats: TrackingStats(
        distance: 5200.0,
        duration: const Duration(minutes: 30),
        averageSpeed: 2.5,
        maxSpeed: 3.0,
      ),
    );

    final dummyBackendActivityJson = {
      '_id': '123',
      'startedAt': '2026-07-16T08:00:00.000Z',
      'endedAt': '2026-07-16T08:30:00.000Z'
    };

    test('1-8. createActivity makes correct POST', () async {
      final service = createService(MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), ApiConstants.activities);
        expect(request.headers['Authorization'], 'Bearer $testToken');
        
        final body = jsonDecode(request.body);
        expect(body['type'], 'running');
        expect(body['startedAt'], isNotNull);
        expect(body['endedAt'], isNotNull);
        expect(body['distance'], 5.2);
        expect(body['trackPoints'][0]['lat'], 1.0);
        expect(body['trackPoints'][0]['lng'], 1.0);

        return http.Response(jsonEncode({
          'activity': dummyBackendActivityJson,
        }), 200);
      }));

      final result = await service.createActivity(session: dummySession, type: 'running');
      expect(result.activity.id, '123');
    });

    test('9-11. getActivities makes GET and interprets list', () async {
      final service = createService(MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), ApiConstants.activities);
        return http.Response(jsonEncode({
          'activities': [dummyBackendActivityJson, dummyBackendActivityJson]
        }), 200);
      }));

      final results = await service.getActivities();
      expect(results.length, 2);
      expect(results.first.id, '123');

      // 11. Devuelve lista vacía cuando activities es null
      final serviceEmpty = createService(MockClient((req) async => http.Response('{}', 200)));
      final emptyResults = await serviceEmpty.getActivities();
      expect(emptyResults, isEmpty);
    });

    test('12-13. getActivityById constructs URL and interprets response', () async {
      final service = createService(MockClient((request) async {
        expect(request.url.toString(), '${ApiConstants.activities}/abc');
        return http.Response(jsonEncode({
          'activity': dummyBackendActivityJson,
          'trackPoints': [{'lat': 2.0, 'lng': 2.0, 'timestamp': '2026-07-16T08:00:00.000Z'}]
        }), 200);
      }));

      final result = await service.getActivityById('abc');
      expect(result.activity.id, '123');
      expect(result.trackPoints.first.latitude, 2.0);
    });

    test('14-16. deleteActivity uses DELETE and handles 200/204', () async {
      int deleteCount = 0;
      final service = createService(MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.toString(), '${ApiConstants.activities}/del-id');
        deleteCount++;
        return http.Response('{}', deleteCount == 1 ? 200 : 204);
      }));

      await service.deleteActivity('del-id');
      await service.deleteActivity('del-id');
      expect(deleteCount, 2);
    });

    test('17-18. Empty ID produces ArgumentError', () async {
      final service = createService(MockClient((r) async => http.Response('', 200)));
      expect(() => service.getActivityById(''), throwsArgumentError);
      expect(() => service.deleteActivity(''), throwsArgumentError);
    });

    test('19. Respuesta inesperada produce FormatException', () async {
      final service = createService(MockClient((r) async => http.Response('[]', 200)));
      expect(() => service.getActivities(), throwsFormatException);
    });

    test('20-21. ApiException 401 y 500 no es ocultada', () async {
      final service = createService(MockClient((r) async => http.Response('Error', 401)));
      expect(() => service.getActivities(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)));

      final service500 = createService(MockClient((r) async => http.Response('Error', 500)));
      expect(() => service500.getActivities(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500)));
    });
  });
}
