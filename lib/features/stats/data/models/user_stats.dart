class OmsStats {
  final int minutosUltimaSemana;
  final int recomendadoMinutosSemana;
  final bool cumpleRecomendacionOMS;
  final double porcentajeCumplido;

  OmsStats({
    required this.minutosUltimaSemana,
    required this.recomendadoMinutosSemana,
    required this.cumpleRecomendacionOMS,
    required this.porcentajeCumplido,
  });

  factory OmsStats.fromJson(Map<String, dynamic> json) {
    return OmsStats(
      minutosUltimaSemana: (json['minutosUltimaSemana'] as num?)?.toInt() ?? 0,
      recomendadoMinutosSemana: (json['recomendadoMinutosSemana'] as num?)?.toInt() ?? 150,
      cumpleRecomendacionOMS: json['cumpleRecomendacionOMS'] == true,
      porcentajeCumplido: (json['porcentajeCumplido'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CalorieBalance {
  final double caloriesBurnedHoy;
  final double caloriesConsumedHoy;
  final double balance;

  CalorieBalance({
    required this.caloriesBurnedHoy,
    required this.caloriesConsumedHoy,
    required this.balance,
  });

  factory CalorieBalance.fromJson(Map<String, dynamic> json) {
    return CalorieBalance(
      caloriesBurnedHoy: (json['caloriesBurnedHoy'] as num?)?.toDouble() ?? 0.0,
      caloriesConsumedHoy: (json['caloriesConsumedHoy'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class UserStats {
  final double totalDistance;
  final int totalActivities;
  final double? bestPace;
  final OmsStats oms;
  final CalorieBalance balanceCalorico;
  final double? imc;

  UserStats({
    required this.totalDistance,
    required this.totalActivities,
    this.bestPace,
    required this.oms,
    required this.balanceCalorico,
    this.imc,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalDistance: (json['totalDistance'] as num?)?.toDouble() ?? 0.0,
      totalActivities: (json['totalActivities'] as num?)?.toInt() ?? 0,
      bestPace: (json['bestPace'] as num?)?.toDouble(),
      oms: OmsStats.fromJson(json['oms'] as Map<String, dynamic>? ?? {}),
      balanceCalorico: CalorieBalance.fromJson(json['balanceCalorico'] as Map<String, dynamic>? ?? {}),
      imc: (json['imc'] as num?)?.toDouble(),
    );
  }
}
