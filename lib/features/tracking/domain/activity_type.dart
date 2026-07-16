enum ActivityType {
  running,
  walking,
  cycling,
  hiking;

  String get apiValue => name;

  static ActivityType fromApiValue(String value) {
    final lowerValue = value.toLowerCase();
    for (final type in ActivityType.values) {
      if (type.apiValue == lowerValue) {
        return type;
      }
    }
    throw ArgumentError('Invalid activity type: $value');
  }

  static ActivityType? tryFromApiValue(String? value) {
    if (value == null) return null;
    final lowerValue = value.toLowerCase();
    for (final type in ActivityType.values) {
      if (type.apiValue == lowerValue) {
        return type;
      }
    }
    return null;
  }
}
