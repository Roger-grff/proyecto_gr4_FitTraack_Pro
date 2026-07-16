import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/providers/api_client_provider.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service.dart';

final activityServiceProvider = Provider<ActivityService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ActivityService(apiClient: apiClient);
});
