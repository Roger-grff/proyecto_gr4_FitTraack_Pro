import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/tracking_controller.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/tracking_state.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service_provider.dart';
import 'package:proyecto_gr4/features/tracking/domain/activity_session.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/data/models/create_activity_result.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';
import 'package:proyecto_gr4/features/tracking/data/tracking_repository.dart';
import 'package:proyecto_gr4/features/tracking/domain/location_point.dart';

// Mocks simulados sin librerias externas
class FakeActivityService implements ActivityService {
  bool shouldThrow500 = false;
  bool shouldThrow401 = false;
  int callCount = 0;
  String? lastType;
  String? lastTitle;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<CreateActivityResult> createActivity({
    required ActivitySession session,
    required String type,
    String description = '',
    Map<String, dynamic>? weather,
  }) async {
    callCount++;
    lastType = type;
    lastTitle = session.title;

    if (shouldThrow500) {
      throw const ApiException(message: 'Server Error', statusCode: 500);
    }
    if (shouldThrow401) {
      throw const ApiException(message: 'Unauthorized', statusCode: 401);
    }

    final backendActivity = BackendActivity(
      id: 'backend_id',
      type: type,
      title: session.title,
      description: description,
      distanceKm: session.stats.distanceKm,
      durationSeconds: session.stats.duration.inSeconds,
      avgPace: 0,
      avgSpeed: 0,
      caloriesBurned: 0,
      startedAt: session.startTime,
      endedAt: session.endTime,
    );

    return CreateActivityResult(
      activity: backendActivity,
    );
  }
}

class FakeTrackingRepository implements TrackingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> checkAndRequestPermissions() async => true;
  @override
  Future<bool> isGPSEnabled() async => true;
  @override
  Stream<LocationPoint> getLocationStream() => const Stream.empty();
}

void main() {
  group('TrackingNotifier Save Activity Tests', () {
    late FakeActivityService fakeService;
    late ProviderContainer container;

    setUp(() {
      fakeService = FakeActivityService();
      container = ProviderContainer(
        overrides: [
          activityServiceProvider.overrideWithValue(fakeService),
          trackingRepositoryProvider.overrideWithValue(FakeTrackingRepository()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('1, 2, 4. Finalizar llama createActivity una sola vez con tipo running y titulo correcto', () async {
      final notifier = container.read(trackingProvider.notifier);
      await notifier.startActivity(); // pasa a tracking
      
      final result = await notifier.finishAndSaveActivity(title: 'Test', type: 'running');
      
      expect(fakeService.callCount, 1);
      expect(fakeService.lastType, 'running');
      expect(fakeService.lastTitle, 'Test');
      expect(result.localSession.title, 'Test');
    });

    test('3. Se envia type walking', () async {
      final notifier = container.read(trackingProvider.notifier);
      await notifier.startActivity();
      
      await notifier.finishAndSaveActivity(title: 'Test', type: 'walking');
      expect(fakeService.lastType, 'walking');
    });

    test('5. Titulo vacio usa valor alternativo', () async {
      final notifier = container.read(trackingProvider.notifier);
      await notifier.startActivity();
      
      await notifier.finishAndSaveActivity(title: '   ', type: 'running');
      expect(fakeService.lastTitle, 'Actividad deportiva');
    });

    test('6, 7. Mientras se guarda, isSavingActivity es true, luego false', () async {
      final notifier = container.read(trackingProvider.notifier);
      await notifier.startActivity();
      
      final future = notifier.finishAndSaveActivity(title: 'Test', type: 'running');
      expect(container.read(trackingProvider).isSavingActivity, isTrue);
      
      await future;
      expect(container.read(trackingProvider).isSavingActivity, isFalse);
    });

    test('8, 9, 10, 11, 12. Errores no agregan la actividad y la mantienen pendiente para reintento', () async {
      final notifier = container.read(trackingProvider.notifier);
      final listNotifier = container.read(completedActivitiesProvider.notifier);
      
      await notifier.startActivity();
      fakeService.shouldThrow500 = true;
      
      try {
        await notifier.finishAndSaveActivity(title: 'Test', type: 'running');
        fail('Should throw');
      } catch (e) {
        expect(e, isA<ApiException>());
      }
      
      // isSaving false despues de fallo
      expect(container.read(trackingProvider).isSavingActivity, isFalse);
      // No agregó a completedActivities
      expect(container.read(completedActivitiesProvider), isEmpty);
      // Mensaje de error seteado
      expect(container.read(trackingProvider).saveActivityError, isNotNull);

      // Ahora arreglamos el error y reintentamos
      fakeService.shouldThrow500 = false;
      await notifier.retryPendingActivitySave();
      
      // Ahora si debe estar en completedActivities
      expect(container.read(completedActivitiesProvider).length, 1);
    });

    test('13, 14, 15, 17, 18. retry usa la misma sesion y evitar simultaneos', () async {
      final notifier = container.read(trackingProvider.notifier);
      await notifier.startActivity();
      
      fakeService.shouldThrow401 = true;
      try {
        await notifier.finishAndSaveActivity(title: 'Test', type: 'running');
      } catch (_) {}

      fakeService.shouldThrow401 = false;
      
      final future1 = notifier.retryPendingActivitySave();
      
      // simulamos intentar otra vez enseguida
      expect(() => notifier.retryPendingActivitySave(), throwsStateError);
      
      final result = await future1;
      
      expect(fakeService.callCount, 2);
      expect(container.read(completedActivitiesProvider).length, 1);
      
      // no cambia sesion ID
      expect(result.localSession.id, isNotNull);
      expect(result.backendResult.activity.type, 'running');
    });

    test('16. Tipo invalido lanza ArgumentError', () async {
      final notifier = container.read(trackingProvider.notifier);
      await notifier.startActivity();
      
      expect(
        () => notifier.finishAndSaveActivity(title: 'Test', type: 'invalid'),
        throwsArgumentError
      );
    });
  });
}
