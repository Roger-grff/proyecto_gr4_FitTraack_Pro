class UpdateProfileRequest {
  final String? name;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? gender;
  final String? activityLevel;

  UpdateProfileRequest({
    this.name,
    this.age,
    this.weightKg,
    this.heightCm,
    this.gender,
    this.activityLevel,
  }) {
    if (name != null) {
      if (name!.trim().isEmpty) {
        throw ArgumentError('El nombre no puede estar vacío.');
      }
    }
    if (gender != null && !['male', 'female', 'other'].contains(gender)) {
      throw ArgumentError('Género inválido.');
    }
    if (activityLevel != null && !['sedentary', 'light', 'moderate', 'active', 'very_active'].contains(activityLevel)) {
      throw ArgumentError('Nivel de actividad inválido.');
    }
    if (age != null && age! <= 0) {
      throw ArgumentError('La edad debe ser mayor a 0.');
    }
    if (weightKg != null && weightKg! <= 0) {
      throw ArgumentError('El peso debe ser mayor a 0.');
    }
    if (heightCm != null && heightCm! <= 0) {
      throw ArgumentError('La altura debe ser mayor a 0.');
    }

    if (name == null &&
        age == null &&
        weightKg == null &&
        heightCm == null &&
        gender == null &&
        activityLevel == null) {
      throw ArgumentError('Se debe proporcionar al menos un campo para actualizar.');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name!.trim();
    if (age != null) data['age'] = age;
    if (weightKg != null) data['weightKg'] = weightKg;
    if (heightCm != null) data['heightCm'] = heightCm;
    if (gender != null) data['gender'] = gender;
    if (activityLevel != null) data['activityLevel'] = activityLevel;
    return data;
  }
}
