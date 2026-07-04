import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'package:proyecto_gr4/features/tracking/domain/location_point.dart';

// Riverpod Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(() {
    service.stopSimulation();
  });
  return service;
});

// Riverpod Provider for TrackingRepository
final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return TrackingRepository(locationService);
});

class TrackingRepository {
  final LocationService _locationService;

  TrackingRepository(this._locationService);

  /// Check GPS status
  Future<bool> isGPSEnabled() => _locationService.isGPSEnabled();

  /// Verify and request permissions
  Future<bool> checkAndRequestPermissions() => 
      _locationService.checkAndRequestPermissions();

  /// Get coordinates stream
  Stream<LocationPoint> getLocationStream() => 
      _locationService.getLocationStream();

  /// Calculate distance in meters between two LocationPoints
  double calculateDistance(LocationPoint start, LocationPoint end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Helper to toggle simulation mode in LocationService
  void setSimulationMode(bool enabled) {
    _locationService.useSimulation = enabled;
  }

  /// Stop simulation if it is running
  void stopSimulation() {
    _locationService.stopSimulation();
  }
}
