import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service_provider.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';

class ActivitiesNotifier extends AsyncNotifier<List<BackendActivity>> {
  late ActivityService _activityService;

  @override
  Future<List<BackendActivity>> build() async {
    _activityService = ref.watch(activityServiceProvider);
    return _loadActivities();
  }

  Future<List<BackendActivity>> _loadActivities() async {
    final activities = await _activityService.getActivities();

    activities.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return activities;
  }

  Future<void> refreshActivities() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadActivities);
  }

  String getErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'Tu sesión expiró. Vuelve a iniciar sesión.';
      }
      return error.message;
    }
    return 'No se pudo cargar el historial. Revisa tu conexión.';
  }
}

final activitiesProvider = AsyncNotifierProvider.autoDispose<ActivitiesNotifier, List<BackendActivity>>(
  ActivitiesNotifier.new,
);
