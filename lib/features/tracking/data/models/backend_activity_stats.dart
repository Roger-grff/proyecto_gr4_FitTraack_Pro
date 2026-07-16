class BackendActivityStats {
  final double elevationGain;
  final double elevationLoss;
  final double maxSpeed;
  final double minPace;
  final int samplingFrequency;

  BackendActivityStats({
    required this.elevationGain,
    required this.elevationLoss,
    required this.maxSpeed,
    required this.minPace,
    required this.samplingFrequency,
  });

  factory BackendActivityStats.fromJson(Map<String, dynamic> json) {
    return BackendActivityStats(
      elevationGain: json['elevationGain'] != null ? (json['elevationGain'] as num).toDouble() : 0.0,
      elevationLoss: json['elevationLoss'] != null ? (json['elevationLoss'] as num).toDouble() : 0.0,
      maxSpeed: json['maxSpeed'] != null ? (json['maxSpeed'] as num).toDouble() : 0.0,
      minPace: json['minPace'] != null ? (json['minPace'] as num).toDouble() : 0.0,
      samplingFrequency: json['samplingFrequency'] != null ? (json['samplingFrequency'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'elevationGain': elevationGain,
      'elevationLoss': elevationLoss,
      'maxSpeed': maxSpeed,
      'minPace': minPace,
      'samplingFrequency': samplingFrequency,
    };
  }
}
