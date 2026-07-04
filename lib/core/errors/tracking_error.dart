enum TrackingErrorType {
  permissionDenied,
  permissionDeniedForever,
  locationServiceDisabled,
  signalLoss,
}

class TrackingError {
  final TrackingErrorType type;
  final String message;

  TrackingError({
    required this.type,
    required this.message,
  });

  @override
  String toString() => message;
}
