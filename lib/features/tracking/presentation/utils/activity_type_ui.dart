import 'package:flutter/material.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/features/tracking/domain/activity_type.dart';

extension ActivityTypeUI on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.running:
        return 'Correr';
      case ActivityType.walking:
        return 'Caminar';
      case ActivityType.cycling:
        return 'Ciclismo';
      case ActivityType.hiking:
        return 'Senderismo';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.hiking:
        return Icons.terrain;
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.running:
        return const Color(0xFF00F5D4); // Cyan/Teal
      case ActivityType.walking:
        return const Color(0xFFFF9F1C); // Orange
      case ActivityType.cycling:
        return const Color(0xFF9D4EDD); // Purple
      case ActivityType.hiking:
        return const Color(0xFF4CAF50); // Green
    }
  }
}

class ActivityTypeHelper {
  static String translate(String? typeApiValue) {
    final type = ActivityType.tryFromApiValue(typeApiValue);
    return type?.displayName ?? 'Actividad';
  }

  static IconData getIcon(String? typeApiValue) {
    final type = ActivityType.tryFromApiValue(typeApiValue);
    return type?.icon ?? Icons.fitness_center;
  }

  static Color getColor(String? typeApiValue) {
    final type = ActivityType.tryFromApiValue(typeApiValue);
    return type?.color ?? AppTheme.primaryColor;
  }
}
