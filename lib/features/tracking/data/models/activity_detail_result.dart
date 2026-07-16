import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity_stats.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_track_point.dart';

class ActivityDetailResult {
  final BackendActivity activity;
  final List<BackendTrackPoint> trackPoints;
  final BackendActivityStats? activityStats;

  ActivityDetailResult({
    required this.activity,
    required this.trackPoints,
    this.activityStats,
  });

  factory ActivityDetailResult.fromJson(Map<String, dynamic> json) {
    if (json['activity'] == null || json['activity'] is! Map) {
      throw const FormatException('Field "activity" is required and must be an object.');
    }

    final activity = BackendActivity.fromJson(json['activity'] as Map<String, dynamic>);
    
    List<BackendTrackPoint> trackPoints = [];
    if (json['trackPoints'] != null && json['trackPoints'] is List) {
      final list = json['trackPoints'] as List;
      trackPoints = list.map((e) => BackendTrackPoint.fromJson(e as Map<String, dynamic>)).toList();
    }

    BackendActivityStats? stats;
    if (json['activityStats'] != null && json['activityStats'] is Map) {
      stats = BackendActivityStats.fromJson(json['activityStats'] as Map<String, dynamic>);
    }

    return ActivityDetailResult(
      activity: activity,
      trackPoints: trackPoints,
      activityStats: stats,
    );
  }
}
