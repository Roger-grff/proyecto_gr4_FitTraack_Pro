import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service_provider.dart';
import 'package:proyecto_gr4/features/tracking/data/models/activity_detail_result.dart';

final activityDetailProvider = FutureProvider.autoDispose.family<ActivityDetailResult, String>((ref, id) async {
  final activityService = ref.watch(activityServiceProvider);
  return activityService.getActivityById(id);
});
