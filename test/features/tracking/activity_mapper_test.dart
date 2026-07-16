import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_gr4/features/tracking/domain/activity_session.dart';
import 'package:proyecto_gr4/features/tracking/domain/location_point.dart';
import 'package:proyecto_gr4/features/tracking/domain/tracking_stats.dart';

void main() {
  group('ActivitySession and LocationPoint toBackendMap Tests', () {
    final startTime = DateTime(2026, 7, 16, 8, 0, 0);
    final endTime = DateTime(2026, 7, 16, 8, 30, 0);
    
    final point = LocationPoint(
      latitude: -0.2186,
      longitude: -78.5085,
      timestamp: startTime,
      altitude: 2800.0,
      speed: 2.5,
      accuracy: 5.0,
    );
    
    final stats = TrackingStats(
      distance: 5200.0, // 5.2 km
      duration: const Duration(minutes: 30),
      averageSpeed: 2.5,
      maxSpeed: 3.0,
    );

    final session = ActivitySession(
      id: 'local_id_123',
      title: 'Carrera matutina',
      startTime: startTime,
      endTime: endTime,
      routePoints: [point],
      stats: stats,
    );

    test('LocationPoint toBackendMap generates correct map', () {
      final map = point.toBackendMap();
      
      expect(map['lat'], equals(-0.2186));
      expect(map['lng'], equals(-78.5085));
      expect(map['altitude'], equals(2800.0));
      expect(map['speed'], equals(2.5));
      expect(map['accuracy'], equals(5.0));
      expect(map['timestamp'], equals(startTime.toIso8601String()));
    });

    test('ActivitySession toBackendMap generates correct map and normalizes types', () {
      final map = session.toBackendMap(type: 'running', weather: null);

      // 1 & 2. startTime/endTime -> startedAt/endedAt
      expect(map['startedAt'], equals(startTime.toIso8601String()));
      expect(map['endedAt'], equals(endTime.toIso8601String()));
      
      // 3. distance in km
      expect(map['distance'], equals(5.2));
      
      // 4. routePoints -> trackPoints
      expect(map.containsKey('trackPoints'), isTrue);
      final trackPoints = map['trackPoints'] as List<Map<String, dynamic>>;
      expect(trackPoints.length, 1);
      
      // 5 & 6. latitude/longitude -> lat/lng
      expect(trackPoints.first['lat'], equals(-0.2186));
      expect(trackPoints.first['lng'], equals(-78.5085));
      
      // 7. type validation
      expect(map['type'], equals('running'));
      
      final walkingMap = session.toBackendMap(type: 'WALKING');
      expect(walkingMap['type'], equals('walking'));
      
      final unknownMap = session.toBackendMap(type: 'flying');
      expect(unknownMap['type'], equals('running')); // Default fallback

      // 8. weather can be null
      expect(map.containsKey('weather'), isTrue);
      expect(map['weather'], isNull);

      // 9 & 10. id and stats are not present
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('stats'), isFalse);
      
      // Additional checks
      expect(map['title'], equals('Carrera matutina'));
    });
  });
}
