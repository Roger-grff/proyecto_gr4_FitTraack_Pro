import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/errors/tracking_error.dart';
import 'package:proyecto_gr4/features/tracking/data/tracking_repository.dart';
import 'package:proyecto_gr4/features/tracking/domain/activity_session.dart';
import 'package:proyecto_gr4/features/tracking/domain/location_point.dart';
import 'timer_controller.dart';
import 'tracking_state.dart';

class TrackingNotifier extends Notifier<TrackingState> {
  StreamSubscription<LocationPoint>? _locationSubscription;
  DateTime? _sessionStartTime;

  TrackingRepository get _repository => ref.read(trackingRepositoryProvider);

  @override
  TrackingState build() {
    // Listen to timer ticks to update active duration and average speed
    ref.listen<Duration>(timerProvider, (previous, next) {
      if (state.status == TrackingStatus.tracking) {
        _updateDuration(next);
      }
    });

    return TrackingState.initial();
  }

  /// Start a new activity session
  Future<void> startActivity() async {
    state = TrackingState.initial().copyWith(status: TrackingStatus.idle);
    ref.read(timerProvider.notifier).reset();
    _sessionStartTime = DateTime.now();

    try {
      // 1. Verify Permissions and GPS hardware
      await _repository.checkAndRequestPermissions();

      // 2. Set state to tracking
      state = state.copyWith(status: TrackingStatus.tracking);

      // 3. Start Timer
      ref.read(timerProvider.notifier).start();

      // 4. Subscribe to Location Stream
      _subscribeToLocation();
    } catch (e) {
      String errMsg = 'Error inesperado';
      if (e is TrackingError) {
        errMsg = e.message;
      } else {
        errMsg = e.toString();
      }
      state = state.copyWith(
        status: TrackingStatus.idle,
        errorMessage: errMsg,
      );
    }
  }

  /// Pause current activity
  void pauseActivity() {
    if (state.status != TrackingStatus.tracking) return;

    state = state.copyWith(status: TrackingStatus.paused);
    ref.read(timerProvider.notifier).pause();
    _unsubscribeFromLocation();
  }

  /// Resume paused activity
  Future<void> resumeActivity() async {
    if (state.status != TrackingStatus.paused) return;

    try {
      // Check GPS again before resuming
      final gpsEnabled = await _repository.isGPSEnabled();
      if (!gpsEnabled) {
        throw TrackingError(
          type: TrackingErrorType.locationServiceDisabled,
          message: 'El GPS está desactivado. Actívalo para continuar.',
        );
      }

      state = state.copyWith(status: TrackingStatus.tracking);
      ref.read(timerProvider.notifier).start();
      _subscribeToLocation();
    } catch (e) {
      state = state.copyWith(
        errorMessage: e is TrackingError ? e.message : e.toString(),
      );
    }
  }

  /// Finish current activity and generate session recap
  void finishActivity(String title) {
    if (state.status != TrackingStatus.tracking && state.status != TrackingStatus.paused) return;

    _unsubscribeFromLocation();
    ref.read(timerProvider.notifier).pause();

    final endTime = DateTime.now();
    final session = ActivitySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      startTime: _sessionStartTime ?? DateTime.now().subtract(state.stats.duration),
      endTime: endTime,
      routePoints: List.from(state.routePoints),
      stats: state.stats,
    );

    // Save the activity in the completed list
    ref.read(completedActivitiesProvider.notifier).addActivity(session);

    state = state.copyWith(
      status: TrackingStatus.finished,
      finishedSession: session,
    );
  }

  /// Reset tracking controller back to idle
  void reset() {
    _unsubscribeFromLocation();
    ref.read(timerProvider.notifier).reset();
    state = TrackingState.initial();
  }

  /// Clear current error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Toggle simulation mode dynamically
  void setSimulationMode(bool enabled) {
    _repository.setSimulationMode(enabled);
    if (state.status == TrackingStatus.tracking) {
      // Restart subscription to use mock/real stream
      _unsubscribeFromLocation();
      _subscribeToLocation();
    }
  }

  /// Subscribe to GPS updates
  void _subscribeToLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = _repository.getLocationStream().listen(
      (LocationPoint point) {
        _handleNewLocation(point);
      },
      onError: (error) {
        String msg = 'Pérdida de señal de GPS';
        if (error is TrackingError) {
          msg = error.message;
        }
        state = state.copyWith(
          errorMessage: msg,
        );
      },
    );
  }

  /// Unsubscribe from GPS updates
  void _unsubscribeFromLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Handle incoming LocationPoint, filter noise, update distance/speeds
  void _handleNewLocation(LocationPoint newPoint) {
    if (state.status != TrackingStatus.tracking) return;

    // Production-ready accuracy filtering: ignore points with bad accuracy (e.g. > 25 meters)
    if (newPoint.accuracy > 25 && !ref.read(locationServiceProvider).useSimulation) {
      // Bad GPS signal, we ignore the point but don't stop tracking
      return;
    }

    final points = List<LocationPoint>.from(state.routePoints);
    double addedDistance = 0.0;

    if (points.isNotEmpty) {
      final lastPoint = points.last;
      // Calculate incremental distance
      addedDistance = _repository.calculateDistance(lastPoint, newPoint);
      
      // Filter out static drift (GPS coordinates changing slightly even when standing still)
      if (addedDistance < 0.5 && newPoint.speed < 0.2) {
        return;
      }
    }

    points.add(newPoint);

    final double newDistance = state.stats.distance + addedDistance;
    final double maxSpd = newPoint.speed > state.stats.maxSpeed ? newPoint.speed : state.stats.maxSpeed;

    // Update state with new points and stats
    state = state.copyWith(
      routePoints: points,
      stats: state.stats.copyWith(
        distance: newDistance,
        currentSpeed: newPoint.speed,
        maxSpeed: maxSpd,
      ),
    );

    // Force recalculating averages based on the current duration
    _updateDuration(ref.read(timerProvider));
  }

  /// Update duration and recompute average speed
  void _updateDuration(Duration duration) {
    final double durationSeconds = duration.inSeconds.toDouble();
    double avgSpeed = 0.0;

    if (durationSeconds > 0) {
      avgSpeed = state.stats.distance / durationSeconds;
    }

    state = state.copyWith(
      stats: state.stats.copyWith(
        duration: duration,
        averageSpeed: avgSpeed,
      ),
    );
  }
}

// Riverpod Provider for TrackingNotifier
final trackingProvider = NotifierProvider<TrackingNotifier, TrackingState>(() {
  return TrackingNotifier();
});

// Riverpod Notifier for completed activities list
class CompletedActivitiesNotifier extends Notifier<List<ActivitySession>> {
  @override
  List<ActivitySession> build() => [];

  void addActivity(ActivitySession session) {
    state = [session, ...state];
  }
}

final completedActivitiesProvider = NotifierProvider<CompletedActivitiesNotifier, List<ActivitySession>>(() {
  return CompletedActivitiesNotifier();
});
