import 'location_point.dart';
import 'tracking_stats.dart';

class ActivitySession {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final List<LocationPoint> routePoints;
  final TrackingStats stats;

  ActivitySession({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.routePoints,
    required this.stats,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'routePoints': routePoints.map((p) => p.toJson()).toList(),
      'stats': stats.toJson(),
    };
  }

  factory ActivitySession.fromJson(Map<String, dynamic> json) {
    return ActivitySession(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Actividad',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      routePoints: (json['routePoints'] as List<dynamic>)
          .map((p) => LocationPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      stats: TrackingStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }
}
