import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/constants/api_constants.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';
import 'package:proyecto_gr4/core/providers/api_client_provider.dart';
import 'package:proyecto_gr4/core/services/api_client.dart';
import 'package:proyecto_gr4/features/stats/data/models/user_stats.dart';

class StatsService {
  final ApiClient apiClient;

  StatsService({required this.apiClient});

  Future<UserStats> getMyStats() async {
    final response = await apiClient.getJson(ApiConstants.statsMe);
    if (response is! Map<String, dynamic> || response['stats'] is! Map<String, dynamic>) {
      throw const ApiException(message: 'Respuesta inválida del servidor.');
    }
    return UserStats.fromJson(response['stats'] as Map<String, dynamic>);
  }
}

final statsServiceProvider = Provider<StatsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StatsService(apiClient: apiClient);
});
