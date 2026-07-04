class TrackingStats {
  final Duration duration;
  final double distance; // in meters
  final double currentSpeed; // in m/s
  final double maxSpeed; // in m/s
  final double averageSpeed; // in m/s

  TrackingStats({
    this.duration = Duration.zero,
    this.distance = 0.0,
    this.currentSpeed = 0.0,
    this.maxSpeed = 0.0,
    this.averageSpeed = 0.0,
  });

  // Helper getters for presentation in km and km/h
  double get distanceKm => distance / 1000.0;
  double get currentSpeedKmH => currentSpeed * 3.6;
  double get maxSpeedKmH => maxSpeed * 3.6;
  double get averageSpeedKmH => averageSpeed * 3.6;

  TrackingStats copyWith({
    Duration? duration,
    double? distance,
    double? currentSpeed,
    double? maxSpeed,
    double? averageSpeed,
  }) {
    return TrackingStats(
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      averageSpeed: averageSpeed ?? this.averageSpeed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'durationMs': duration.inMilliseconds,
      'distance': distance,
      'currentSpeed': currentSpeed,
      'maxSpeed': maxSpeed,
      'averageSpeed': averageSpeed,
    };
  }

  factory TrackingStats.fromJson(Map<String, dynamic> json) {
    return TrackingStats(
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      distance: json['distance'] as double? ?? 0.0,
      currentSpeed: json['currentSpeed'] as double? ?? 0.0,
      maxSpeed: json['maxSpeed'] as double? ?? 0.0,
      averageSpeed: json['averageSpeed'] as double? ?? 0.0,
    );
  }
}
