import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service_provider.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/activities_controller.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';
import 'package:proyecto_gr4/features/tracking/domain/activity_session.dart';
import 'package:proyecto_gr4/features/tracking/data/models/create_activity_result.dart';

class FakeActivityService implements ActivityService {
  List<BackendActivity> mockActivities = [];
  bool throw401 = false;
  bool throw500 = false;
  int getActivitiesCallCount = 0;

  @override
  Future<List<BackendActivity>> getActivities() async {
    getActivitiesCallCount++;
    if (throw401) throw const ApiException(message: 'Unauthorized', statusCode: 401);
    if (throw500) throw const ApiException(message: 'Server Error', statusCode: 500);
    return List.from(mockActivities);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ActivitiesController Tests', () {
    late FakeActivityService fakeService;

    setUp(() {
      fakeService = FakeActivityService();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [
          activityServiceProvider.overrideWithValue(fakeService),
        ],
      );
    }

    test('1, 2, 3. Al construirse ejecuta GET, interpreta la lista y ordena por fecha', () async {
      fakeService.mockActivities = [
        BackendActivity(
          id: '1', type: 'running', title: 'Old', description: '',
          distanceKm: 1, durationSeconds: 60, avgPace: 0, avgSpeed: 0, caloriesBurned: 0,
          startedAt: DateTime(2023, 1, 1), endedAt: DateTime(2023, 1, 1),
        ),
        BackendActivity(
          id: '2', type: 'walking', title: 'New', description: '',
          distanceKm: 2, durationSeconds: 120, avgPace: 0, avgSpeed: 0, caloriesBurned: 0,
          startedAt: DateTime(2023, 1, 2), endedAt: DateTime(2023, 1, 2),
        ),
      ];

      final container = makeContainer();
      // Leemos el future directamente
      final activities = await container.read(activitiesProvider.future);

      expect(fakeService.getActivitiesCallCount, 1);
      expect(activities.length, 2);
      expect(activities.first.title, 'New'); // El más reciente primero
      expect(activities.last.title, 'Old');
    });

    test('4, 5. Lista vacía produce data vacío', () async {
      fakeService.mockActivities = [];
      final container = makeContainer();
      final activities = await container.read(activitiesProvider.future);
      expect(activities, isEmpty);
    });

    test('6. Error 401 produce AsyncError con mensaje especifico', () async {
      fakeService.throw401 = true;
      final container = makeContainer();
      final subscription = container.listen(activitiesProvider, (_, __) {});
      final notifier = container.read(activitiesProvider.notifier);

      try {
        await notifier.refreshActivities();
      } catch (_) {}

      final state = subscription.read();
      expect(state.hasError, isTrue);
      expect(notifier.getErrorMessage(state.error!), 'Tu sesión expiró. Vuelve a iniciar sesión.');
    });

    test('7. Error 500 produce AsyncError con mensaje del server', () async {
      fakeService.throw500 = true;
      final container = makeContainer();
      final subscription = container.listen(activitiesProvider, (_, __) {});
      final notifier = container.read(activitiesProvider.notifier);

      try {
        await notifier.refreshActivities();
      } catch (_) {}

      final state = subscription.read();
      expect(state.hasError, isTrue);
      expect(notifier.getErrorMessage(state.error!), 'Server Error');
    });

    test('8, 9, 10. refreshActivities realiza nueva solicitud y entra a loading', () async {
      fakeService.mockActivities = [
        BackendActivity(
          id: '1', type: 'running', title: 'First', description: '',
          distanceKm: 1, durationSeconds: 60, avgPace: 0, avgSpeed: 0, caloriesBurned: 0,
          startedAt: DateTime(2023, 1, 1), endedAt: DateTime(2023, 1, 1),
        ),
      ];

      final container = makeContainer();
      container.listen(activitiesProvider, (_, __) {}); // Keep alive
      await container.read(activitiesProvider.future);

      expect(fakeService.getActivitiesCallCount, 1);

      // Cambiamos datos en backend
      fakeService.mockActivities.add(
        BackendActivity(
          id: '2', type: 'walking', title: 'Second', description: '',
          distanceKm: 2, durationSeconds: 120, avgPace: 0, avgSpeed: 0, caloriesBurned: 0,
          startedAt: DateTime(2023, 1, 2), endedAt: DateTime(2023, 1, 2),
        ),
      );

      final notifier = container.read(activitiesProvider.notifier);
      final future = notifier.refreshActivities();

      // Deberia estar en loading inmediatamente
      expect(container.read(activitiesProvider).isLoading, isTrue);

      await future;

      expect(fakeService.getActivitiesCallCount, 2);
      final newState = container.read(activitiesProvider);
      expect(newState.value!.length, 2);
    });
  });
}
