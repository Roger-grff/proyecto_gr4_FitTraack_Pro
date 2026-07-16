import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service_provider.dart';
import 'package:proyecto_gr4/features/tracking/data/models/activity_detail_result.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity_stats.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/activity_detail_controller.dart';

class MockActivityService implements ActivityService {
  @override
  Future<ActivityDetailResult> getActivityById(String id) async {
    if (id == 'error') {
      throw ApiException(message: 'Error mock', statusCode: 404);
    }
    return ActivityDetailResult(
      activity: BackendActivity(
        id: id,
        userId: 'u1',
        title: 'Mock Title',
        type: 'running',
        description: '',
        startedAt: DateTime.parse('2024-01-01T10:00:00Z'),
        endedAt: DateTime.parse('2024-01-01T10:30:00Z'),
        distanceKm: 5.0,
        durationSeconds: 1800,
        avgSpeed: 10.0,
        avgPace: 6.0,
        caloriesBurned: 300,
      ),
      activityStats: BackendActivityStats(
        elevationGain: 0.0,
        elevationLoss: 0.0,
        maxSpeed: 0.0,
        minPace: 0.0,
        samplingFrequency: 10,
      ),
      trackPoints: [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;
  late MockActivityService mockService;

  setUp(() {
    mockService = MockActivityService();
    container = ProviderContainer(
      overrides: [
        activityServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ActivityDetailProvider Tests', () {
    test('1. Obtiene el detalle correctamente al inicializarse', () async {
      // Act
      final provider = activityDetailProvider('123');
      final subscription = container.listen(provider, (_, __) {});
      
      final result = await container.read(provider.future);
      
      // Assert
      expect(result.activity.id, '123');
      expect(result.activity.title, 'Mock Title');
      expect(result.activity.caloriesBurned, 300);
      
      subscription.close();
    });



    test('3. ref.invalidate vuelve a cargar los datos', () async {
      final provider = activityDetailProvider('123');
      final subscription = container.listen(provider, (_, __) {});
      
      // Wait for initial load
      await container.read(provider.future);
      
      // Call invalidate
      container.invalidate(provider);
      
      final state = container.read(provider);
      expect(state.isLoading, true);
      
      subscription.close();
    });
  });
}
