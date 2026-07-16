import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity_stats.dart';

class CreateActivityResult {
  final BackendActivity activity;
  final BackendActivityStats? activityStats;
  final int trackPointsGuardados;
  final bool caloriesBurnedEstimated;

  CreateActivityResult({
    required this.activity,
    this.activityStats,
    this.trackPointsGuardados = 0,
    this.caloriesBurnedEstimated = false,
  });

  factory CreateActivityResult.fromJson(Map<String, dynamic> json) {
    if (json['activity'] == null || json['activity'] is! Map) {
      throw const FormatException('Field "activity" is required and must be an object.');
    }

    final activity = BackendActivity.fromJson(json['activity'] as Map<String, dynamic>);
    
    BackendActivityStats? stats;
    if (json['activityStats'] != null && json['activityStats'] is Map) {
      stats = BackendActivityStats.fromJson(json['activityStats'] as Map<String, dynamic>);
    }

    return CreateActivityResult(
      activity: activity,
      activityStats: stats,
      trackPointsGuardados: json['trackPointsGuardados'] != null ? (json['trackPointsGuardados'] as num).toInt() : 0,
      caloriesBurnedEstimated: json['caloriesBurnedEstimated'] == true,
    );
  }
}
