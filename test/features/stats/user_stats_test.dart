import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_gr4/features/stats/data/models/user_stats.dart';

void main() {
  group('UserStats Tests', () {
    test('1. Parsea correctamente JSON de /api/stats/me', () {
      final json = {
        "totalDistance": 42.5,
        "totalActivities": 8,
        "bestPace": 5.1,
        "oms": {
          "minutosUltimaSemana": 120,
          "recomendadoMinutosSemana": 150,
          "cumpleRecomendacionOMS": false,
          "porcentajeCumplido": 80.0
        },
        "balanceCalorico": {
          "caloriesBurnedHoy": 420,
          "caloriesConsumedHoy": 1800,
          "balance": 1380
        },
        "imc": 22.9
      };

      final stats = UserStats.fromJson(json);

      expect(stats.totalDistance, 42.5);
      expect(stats.totalActivities, 8);
      expect(stats.bestPace, 5.1);
      
      expect(stats.oms.minutosUltimaSemana, 120);
      expect(stats.oms.cumpleRecomendacionOMS, false);
      expect(stats.oms.porcentajeCumplido, 80.0);

      expect(stats.balanceCalorico.balance, 1380);
      expect(stats.imc, 22.9);
    });

    test('2. Maneja valores nulos sin fallar', () {
      final json = {
        "totalDistance": null,
        "totalActivities": null,
        "bestPace": null,
        "oms": null,
        "balanceCalorico": null,
        "imc": null
      };

      final stats = UserStats.fromJson(json);

      expect(stats.totalDistance, 0.0);
      expect(stats.totalActivities, 0);
      expect(stats.bestPace, null);
      
      expect(stats.oms.minutosUltimaSemana, 0);
      expect(stats.balanceCalorico.balance, 0.0);
      expect(stats.imc, null);
    });
  });
}
