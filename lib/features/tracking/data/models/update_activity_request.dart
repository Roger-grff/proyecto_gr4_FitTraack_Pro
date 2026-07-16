import 'package:proyecto_gr4/features/tracking/domain/activity_type.dart';

class UpdateActivityRequest {
  final String? title;
  final String? description;
  final String? type;

  UpdateActivityRequest({
    this.title,
    this.description,
    this.type,
  }) {
    if (title != null && title!.trim().isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    if (type != null) {
      // Validar estrictamente el tipo para asegurar que sea de los 4 permitidos
      ActivityType.fromApiValue(type!);
    }
    if (title == null && description == null && type == null) {
      throw ArgumentError('At least one field must be provided for update');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title!.trim();
    if (description != null) data['description'] = description;
    if (type != null) {
      final validActivityType = ActivityType.fromApiValue(type!);
      data['type'] = validActivityType.apiValue;
    }
    return data;
  }
}
