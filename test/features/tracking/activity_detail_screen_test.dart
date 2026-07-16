import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service_provider.dart';
import 'package:proyecto_gr4/features/tracking/data/models/activity_detail_result.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity_stats.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_track_point.dart';
import 'package:proyecto_gr4/features/tracking/presentation/screens/activity_detail_screen.dart';

class MockActivityService implements ActivityService {
  final ActivityDetailResult? resultToReturn;
  final bool shouldThrow;

  MockActivityService({this.resultToReturn, this.shouldThrow = false});

  @override
  Future<ActivityDetailResult> getActivityById(String id) async {
    if (shouldThrow) throw Exception('Mock Error');
    return resultToReturn ??
        ActivityDetailResult(
          activity: BackendActivity(
            id: id,
            userId: 'u1',
            title: 'Mock Activity',
            type: 'running',
            description: '',
            startedAt: DateTime.now(),
            endedAt: DateTime.now(),
            distanceKm: 2.5,
            durationSeconds: 900,
            avgSpeed: 10.0,
            avgPace: 6.0,
            caloriesBurned: 150,
          ),
          activityStats: BackendActivityStats(
            elevationGain: 0,
            elevationLoss: 0,
            maxSpeed: 0,
            minPace: 0,
            samplingFrequency: 10,
          ),
          trackPoints: [],
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createWidgetUnderTest(ActivityService mockService) {
    return ProviderScope(
      overrides: [
        activityServiceProvider.overrideWithValue(mockService),
      ],
      child: const MaterialApp(
        home: ActivityDetailScreen(activityId: 'test-id'),
      ),
    );
  }

  group('ActivityDetailScreen Tests', () {
    testWidgets('1. Muestra CircularProgressIndicator mientras carga', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(MockActivityService()));
      
      // Assert - We check before the future completes
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Allow it to finish
      await tester.pumpAndSettle();
    });

    testWidgets('2. Muestra mensaje de error y boton reintentar', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(MockActivityService(shouldThrow: true)));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Error al cargar detalle'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('3. Muestra "Esta actividad no tiene una ruta GPS" cuando no hay puntos', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(MockActivityService(
        resultToReturn: ActivityDetailResult(
          activity: BackendActivity(
            id: '1', userId: '1', title: 'Test', type: 'running', description: '',
            startedAt: DateTime.now(), endedAt: DateTime.now(), distanceKm: 0, durationSeconds: 0, avgSpeed: 0, avgPace: 0, caloriesBurned: 0,
          ),
          activityStats: BackendActivityStats(elevationGain: 0, elevationLoss: 0, maxSpeed: 0, minPace: 0, samplingFrequency: 10),
          trackPoints: [],
        ),
      )));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Esta actividad no tiene una ruta GPS disponible'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
    });

    testWidgets('4. Muestra FlutterMap y marcadores cuando hay puntos válidos', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(MockActivityService(
        resultToReturn: ActivityDetailResult(
          activity: BackendActivity(
            id: '1', userId: '1', title: 'Test Map', type: 'running', description: '',
            startedAt: DateTime.now(), endedAt: DateTime.now(), distanceKm: 0, durationSeconds: 0, avgSpeed: 0, avgPace: 0, caloriesBurned: 0,
          ),
          activityStats: BackendActivityStats(elevationGain: 0, elevationLoss: 0, maxSpeed: 0, minPace: 0, samplingFrequency: 10),
          trackPoints: [
            BackendTrackPoint(latitude: 0, longitude: 0, altitude: 0, speed: 0, accuracy: 0, timestamp: DateTime.now()),
            BackendTrackPoint(latitude: 1, longitude: 1, altitude: 0, speed: 0, accuracy: 0, timestamp: DateTime.now()),
          ],
        ),
      )));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);
    });

    testWidgets('5. Muestra los datos de la actividad correctamente', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(MockActivityService(
        resultToReturn: ActivityDetailResult(
          activity: BackendActivity(
            id: '1', userId: '1', title: 'Mi Gran Carrera', type: 'running', description: '',
            startedAt: DateTime.now(), endedAt: DateTime.now(), distanceKm: 12.34, durationSeconds: 3600, avgSpeed: 0, avgPace: 5.5, caloriesBurned: 550,
          ),
          activityStats: BackendActivityStats(elevationGain: 0, elevationLoss: 0, maxSpeed: 0, minPace: 0, samplingFrequency: 10),
          trackPoints: [],
        ),
      )));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Mi Gran Carrera'), findsOneWidget);
      expect(find.text('12.34 km'), findsOneWidget);
      expect(find.text('01:00:00'), findsOneWidget);
      expect(find.text('550 kcal'), findsOneWidget);
      expect(find.text('5.50 min/km'), findsOneWidget);
    });
  });
}
