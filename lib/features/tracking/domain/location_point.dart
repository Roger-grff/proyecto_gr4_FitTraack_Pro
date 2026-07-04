class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speed; // in m/s
  final double altitude;
  final double accuracy;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed = 0.0,
    this.altitude = 0.0,
    this.accuracy = 0.0,
  });

  // Calculate speed in km/h
  double get speedKmH => speed * 3.6;

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'altitude': altitude,
      'accuracy': accuracy,
    };
  }

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: json['speed'] as double? ?? 0.0,
      altitude: json['altitude'] as double? ?? 0.0,
      accuracy: json['accuracy'] as double? ?? 0.0,
    );
  }
}
