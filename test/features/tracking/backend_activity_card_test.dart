import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/presentation/widgets/backend_activity_card.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  group('BackendActivityCard Tests', () {
    Widget createWidgetUnderTest(BackendActivity activity) {
      return MaterialApp(
        home: Scaffold(
          body: BackendActivityCard(activity: activity),
        ),
      );
    }

    testWidgets('1, 2, 4, 5. Muestra running traducido, dist y duracion', (tester) async {
      final activity = BackendActivity(
        id: '1',
        type: 'running',
        title: 'Trote matutino',
        description: '',
        distanceKm: 5.2,
        durationSeconds: 3600 + 1800, // 1h 30m
        avgSpeed: 0,
        avgPace: 5.5,
        caloriesBurned: 300,
        startedAt: DateTime(2023, 1, 1),
        endedAt: DateTime(2023, 1, 1),
      );

      await tester.pumpWidget(createWidgetUnderTest(activity));

      expect(find.text('Trote matutino'), findsOneWidget);
      expect(find.text('Correr'), findsOneWidget);
      expect(find.text('5.20 km'), findsOneWidget);
      expect(find.text('1h 30m'), findsOneWidget);
      expect(find.text('Ritmo'), findsOneWidget);
      expect(find.text('5.50 /km'), findsOneWidget);
    });

    testWidgets('3. Muestra walking traducido y velocidad', (tester) async {
      final activity = BackendActivity(
        id: '2',
        type: 'walking',
        title: 'Caminata relajada',
        description: '',
        distanceKm: 2.0,
        durationSeconds: 1205, // 20m 5s
        avgSpeed: 4.5,
        avgPace: 0,
        caloriesBurned: 100,
        startedAt: DateTime(2023, 1, 1),
        endedAt: DateTime(2023, 1, 1),
      );

      await tester.pumpWidget(createWidgetUnderTest(activity));

      expect(find.text('Caminata relajada'), findsOneWidget);
      expect(find.text('Caminar'), findsOneWidget);
      expect(find.text('2.00 km'), findsOneWidget);
      expect(find.text('20m 5s'), findsOneWidget);
      expect(find.text('Vel. Promedio'), findsOneWidget);
      expect(find.text('4.5 km/h'), findsOneWidget);
    });
  });
}
