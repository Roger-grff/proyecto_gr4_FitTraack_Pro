class BackendActivity {
  final String id;
  final String? userId;
  final String type;
  final String title;
  final String description;
  final double distanceKm;
  final int durationSeconds;
  final double avgPace;
  final double avgSpeed;
  final int caloriesBurned;
  final String? status;
  final Map<String, dynamic>? weather;
  final String? locationName;
  final DateTime startedAt;
  final DateTime endedAt;

  BackendActivity({
    required this.id,
    this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgPace,
    required this.avgSpeed,
    required this.caloriesBurned,
    this.status,
    this.weather,
    this.locationName,
    required this.startedAt,
    required this.endedAt,
  });

  Duration get duration => Duration(seconds: durationSeconds);
  bool get isRunning => type.toLowerCase() == 'running';
  bool get isWalking => type.toLowerCase() == 'walking';

  factory BackendActivity.fromJson(Map<String, dynamic> json) {
    if (json['_id'] == null || json['startedAt'] == null || json['endedAt'] == null) {
      throw const FormatException('Fields _id, startedAt, and endedAt are required.');
    }

    return BackendActivity(
      id: json['_id'] as String,
      userId: json['userId'] as String?,
      type: json['type'] as String? ?? 'unknown',
      title: json['title'] as String? ?? 'Actividad',
      description: json['description'] as String? ?? '',
      distanceKm: json['distance'] != null ? (json['distance'] as num).toDouble() : 0.0,
      durationSeconds: json['duration'] != null ? (json['duration'] as num).toInt() : 0,
      avgPace: json['avgPace'] != null ? (json['avgPace'] as num).toDouble() : 0.0,
      avgSpeed: json['avgSpeed'] != null ? (json['avgSpeed'] as num).toDouble() : 0.0,
      caloriesBurned: json['caloriesBurned'] != null ? (json['caloriesBurned'] as num).toInt() : 0,
      status: json['status'] as String?,
      weather: json['weather'] as Map<String, dynamic>?,
      locationName: json['locationName'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'distance': distanceKm,
      'duration': durationSeconds,
      'avgPace': avgPace,
      'avgSpeed': avgSpeed,
      'caloriesBurned': caloriesBurned,
      'status': status,
      'weather': weather,
      'locationName': locationName,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
    };
  }
}
