class BackendTrackPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double accuracy;
  final DateTime timestamp;

  BackendTrackPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
  });

  factory BackendTrackPoint.fromJson(Map<String, dynamic> json) {
    if (json['lat'] == null || json['lng'] == null || json['timestamp'] == null) {
      throw const FormatException('lat, lng and timestamp are required fields.');
    }

    return BackendTrackPoint(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      altitude: json['altitude'] != null ? (json['altitude'] as num).toDouble() : 0.0,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : 0.0,
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lng': longitude,
      'altitude': altitude,
      'speed': speed,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
