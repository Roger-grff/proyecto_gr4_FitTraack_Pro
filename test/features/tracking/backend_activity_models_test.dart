import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity_stats.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_track_point.dart';
import 'package:proyecto_gr4/features/tracking/data/models/activity_detail_result.dart';
import 'package:proyecto_gr4/features/tracking/data/models/create_activity_result.dart';

void main() {
  group('Backend Activity Models Tests', () {
    test('1. BackendTrackPoint convierte lat y lng', () {
      final json = {
        'lat': -0.2186,
        'lng': -78.5085,
        'timestamp': '2026-07-16T08:00:00.000Z'
      };
      final pt = BackendTrackPoint.fromJson(json);
      expect(pt.latitude, -0.2186);
      expect(pt.longitude, -78.5085);
    });

    test('2. BackendTrackPoint acepta int y double', () {
      final json = {
        'lat': -0.2186,
        'lng': -78,
        'altitude': 2800,
        'speed': 2,
        'accuracy': 5.5,
        'timestamp': '2026-07-16T08:00:00.000Z'
      };
      final pt = BackendTrackPoint.fromJson(json);
      expect(pt.longitude, -78.0);
      expect(pt.altitude, 2800.0);
      expect(pt.speed, 2.0);
    });

    test('3 & 4. BackendActivity convierte _id en id y distance en distanceKm', () {
      final json = {
        '_id': '123',
        'type': 'running',
        'title': 'Test',
        'description': '',
        'distance': 5.5,
        'duration': 1800,
        'avgPace': 5.77,
        'avgSpeed': 10.4,
        'caloriesBurned': 420,
        'startedAt': '2026-07-16T08:00:00.000Z',
        'endedAt': '2026-07-16T08:30:00.000Z'
      };
      final act = BackendActivity.fromJson(json);
      expect(act.id, '123');
      expect(act.distanceKm, 5.5);
    });

    test('5. BackendActivity acepta números enteros y decimales', () {
      final json = {
        '_id': '123',
        'distance': 5,
        'duration': 1800.0,
        'avgPace': 5,
        'avgSpeed': 10,
        'caloriesBurned': 420.5,
        'startedAt': '2026-07-16T08:00:00.000Z',
        'endedAt': '2026-07-16T08:30:00.000Z'
      };
      final act = BackendActivity.fromJson(json);
      expect(act.distanceKm, 5.0);
      expect(act.durationSeconds, 1800);
      expect(act.caloriesBurned, 420);
      expect(act.avgSpeed, 10.0);
    });

    test('6. BackendActivity convierte fechas', () {
      final json = {
        '_id': '123',
        'startedAt': '2026-07-16T08:00:00.000Z',
        'endedAt': '2026-07-16T08:30:00.000Z'
      };
      final act = BackendActivity.fromJson(json);
      expect(act.startedAt.year, 2026);
      expect(act.endedAt.minute, 30);
    });

    test('7. BackendActivity tolera campos opcionales null', () {
      final json = {
        '_id': '123',
        'startedAt': '2026-07-16T08:00:00.000Z',
        'endedAt': '2026-07-16T08:30:00.000Z',
        'weather': null,
        'status': null,
        'locationName': null,
        'userId': null
      };
      final act = BackendActivity.fromJson(json);
      expect(act.weather, isNull);
      expect(act.status, isNull);
      expect(act.locationName, isNull);
      expect(act.userId, isNull);
    });

    test('8. BackendActivityStats interpreta sus valores', () {
      final json = {
        'elevationGain': 12,
        'elevationLoss': 5.5,
        'maxSpeed': 11,
        'minPace': 5.1,
        'samplingFrequency': 60
      };
      final stats = BackendActivityStats.fromJson(json);
      expect(stats.elevationGain, 12.0);
      expect(stats.samplingFrequency, 60);
    });

    test('9 & 10. ActivityDetailResult interpreta trackPoints y lista vacia', () {
      final activityJson = {
        '_id': '123',
        'startedAt': '2026-07-16T08:00:00.000Z',
        'endedAt': '2026-07-16T08:30:00.000Z'
      };
      
      final emptyResult = ActivityDetailResult.fromJson({
        'activity': activityJson,
        'trackPoints': []
      });
      expect(emptyResult.trackPoints.isEmpty, isTrue);

      final fullResult = ActivityDetailResult.fromJson({
        'activity': activityJson,
        'trackPoints': [
          {'lat': 1, 'lng': 1, 'timestamp': '2026-07-16T08:00:00.000Z'}
        ]
      });
      expect(fullResult.trackPoints.length, 1);
      expect(fullResult.trackPoints.first.latitude, 1.0);
    });

    test('11 & 12. CreateActivityResult interpreta activity y maneja opcionales', () {
      final activityJson = {
        '_id': '123',
        'startedAt': '2026-07-16T08:00:00.000Z',
        'endedAt': '2026-07-16T08:30:00.000Z'
      };
      
      final result = CreateActivityResult.fromJson({
        'activity': activityJson,
        'trackPointsGuardados': 2,
        'caloriesBurnedEstimated': true
      });
      
      expect(result.activity.id, '123');
      expect(result.trackPointsGuardados, 2);
      expect(result.caloriesBurnedEstimated, isTrue);
      expect(result.activityStats, isNull);
    });
  });
}
