import 'package:proyecto_gr4/features/tracking/domain/activity_session.dart';
import 'package:proyecto_gr4/features/tracking/domain/location_point.dart';
import 'package:proyecto_gr4/features/tracking/domain/tracking_stats.dart';

enum TrackingStatus {
  idle,
  tracking,
  paused,
  finished,
}

class TrackingState {
  final TrackingStatus status;
  final List<LocationPoint> routePoints;
  final TrackingStats stats;
  final String? errorMessage;
  final ActivitySession? finishedSession;

  TrackingState({
    this.status = TrackingStatus.idle,
    this.routePoints = const [],
    required this.stats,
    this.errorMessage,
    this.finishedSession,
  });

  factory TrackingState.initial() {
    return TrackingState(
      stats: TrackingStats(),
    );
  }

  TrackingState copyWith({
    TrackingStatus? status,
    List<LocationPoint>? routePoints,
    TrackingStats? stats,
    String? errorMessage,
    ActivitySession? finishedSession,
    bool clearError = false,
  }) {
    return TrackingState(
      status: status ?? this.status,
      routePoints: routePoints ?? this.routePoints,
      stats: stats ?? this.stats,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      finishedSession: finishedSession ?? this.finishedSession,
    );
  }
}
