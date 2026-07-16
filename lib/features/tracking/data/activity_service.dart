import 'package:proyecto_gr4/core/constants/api_constants.dart';
import 'package:proyecto_gr4/core/services/api_client.dart';
import 'package:proyecto_gr4/features/tracking/domain/activity_session.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/data/models/activity_detail_result.dart';
import 'package:proyecto_gr4/features/tracking/data/models/create_activity_result.dart';

class ActivityService {
  final ApiClient apiClient;

  const ActivityService({
    required this.apiClient,
  });

  Future<CreateActivityResult> createActivity({
    required ActivitySession session,
    required String type,
    String description = '',
    Map<String, dynamic>? weather,
  }) async {
    final body = session.toBackendMap(
      type: type,
      description: description,
      weather: weather,
    );

    final response = await apiClient.postJson(
      ApiConstants.activities,
      body: body,
    );

    if (response is! Map<String, dynamic>) {
      throw const FormatException('La respuesta del servidor no es un JSON válido.');
    }

    return CreateActivityResult.fromJson(response);
  }

  Future<List<BackendActivity>> getActivities() async {
    final response = await apiClient.getJson(ApiConstants.activities);

    if (response is! Map<String, dynamic>) {
      throw const FormatException('La respuesta del servidor no es un mapa JSON válido.');
    }

    final activitiesList = response['activities'];
    if (activitiesList == null) {
      return [];
    }

    if (activitiesList is! List) {
      throw const FormatException('El campo "activities" no es una lista.');
    }

    return activitiesList.map((e) => BackendActivity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ActivityDetailResult> getActivityById(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('El id no puede estar vacío.');
    }

    final url = '${ApiConstants.activities}/$id';
    final response = await apiClient.getJson(url);

    if (response is! Map<String, dynamic>) {
      throw const FormatException('La respuesta del servidor no es un mapa JSON válido.');
    }

    return ActivityDetailResult.fromJson(response);
  }

  Future<void> deleteActivity(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('El id no puede estar vacío.');
    }

    final url = '${ApiConstants.activities}/$id';
    await apiClient.deleteJson(url);
  }
}
