import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:proyecto_gr4/core/errors/tracking_error.dart';
import 'package:proyecto_gr4/features/tracking/domain/location_point.dart';

class LocationService {
  bool _useSimulation = false;
  
  // Getter/Setter to toggle simulation mode
  bool get useSimulation => _useSimulation;
  set useSimulation(bool value) => _useSimulation = value;

  // Stream controller for simulated points
  StreamController<LocationPoint>? _simulatedController;
  Timer? _simulationTimer;
  double _simulatedLat = 4.7110; // Default simulated location (e.g., Bogota center, or we can use another)
  double _simulatedLng = -74.0721;
  double _simulatedRouteAngle = 0.0;

  /// Check location services (GPS hardware status)
  Future<bool> isGPSEnabled() async {
    if (_useSimulation) return true;
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request Location Permissions using permission_handler
  Future<bool> checkAndRequestPermissions() async {
    if (_useSimulation) return true;

    // Check GPS service first
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      throw TrackingError(
        type: TrackingErrorType.locationServiceDisabled,
        message: 'El servicio de GPS está desactivado. Por favor, actívalo en los ajustes.',
      );
    }

    // Check permission status
    var status = await Permission.location.status;

    if (status.isDenied) {
      // Request permission
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      throw TrackingError(
        type: TrackingErrorType.permissionDeniedForever,
        message: 'Los permisos de ubicación han sido denegados de forma permanente. Por favor, actívalos desde la configuración de la aplicación.',
      );
    }

    if (!status.isGranted && !status.isLimited) {
      throw TrackingError(
        type: TrackingErrorType.permissionDenied,
        message: 'No se puede acceder a la ubicación porque los permisos fueron denegados.',
      );
    }

    return true;
  }

  /// Get real or simulated location stream
  Stream<LocationPoint> getLocationStream() {
    if (_useSimulation) {
      return _getSimulatedLocationStream();
    } else {
      return _getRealLocationStream();
    }
  }

  /// Get real GPS stream mapped to LocationPoint
  Stream<LocationPoint> _getRealLocationStream() {
    // Setup location settings for high accuracy real-time tracking
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, // Emit update every 2 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((Position position) {
      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
        speed: position.speed,
        altitude: position.altitude,
        accuracy: position.accuracy,
      );
    }).handleError((error) {
      // Handle potential location errors
      if (error is LocationServiceDisabledException) {
        throw TrackingError(
          type: TrackingErrorType.locationServiceDisabled,
          message: 'El GPS se desactivó durante la actividad.',
        );
      }
      throw TrackingError(
        type: TrackingErrorType.signalLoss,
        message: 'Error al obtener coordenadas de ubicación: ${error.toString()}',
      );
    });
  }

  /// Generate a simulated GPS stream that follows a nice curved route
  Stream<LocationPoint> _getSimulatedLocationStream() {
    _simulatedController?.close();
    _simulationTimer?.cancel();

    _simulatedController = StreamController<LocationPoint>.broadcast();
    
    // Seed initial coordinates (e.g., Bogota)
    _simulatedLat = 4.7110;
    _simulatedLng = -74.0721;
    _simulatedRouteAngle = 0.0;

    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_simulatedController == null || _simulatedController!.isClosed) {
        timer.cancel();
        return;
      }

      // Generate a nice route (walking speed ~ 1.5 m/s, moving slightly)
      // Angle changes slightly to make a curve
      _simulatedRouteAngle += (math.Random().nextDouble() - 0.5) * 0.4;
      
      // Walking distance in degrees (approx 3 meters)
      const double latStep = 0.000027; // Approx 3 meters
      const double lngStep = 0.000027;

      _simulatedLat += math.sin(_simulatedRouteAngle) * latStep;
      _simulatedLng += math.cos(_simulatedRouteAngle) * lngStep;

      // Speed fluctuates between 1.2 m/s (4.3 km/h) and 1.8 m/s (6.5 km/h)
      final double simulatedSpeed = 1.2 + math.Random().nextDouble() * 0.6;
      final double accuracy = 3.0 + math.Random().nextDouble() * 2.0;

      final point = LocationPoint(
        latitude: _simulatedLat,
        longitude: _simulatedLng,
        timestamp: DateTime.now(),
        speed: simulatedSpeed,
        altitude: 2600.0 + math.Random().nextDouble() * 5,
        accuracy: accuracy,
      );

      if (!_simulatedController!.isClosed) {
        _simulatedController!.add(point);
      }
    });

    return _simulatedController!.stream;
  }

  /// Stop simulation timer if active
  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _simulatedController?.close();
    _simulatedController = null;
  }
}
