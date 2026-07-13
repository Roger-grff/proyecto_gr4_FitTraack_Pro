class AppUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? gender;
  final String? activityLevel;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.age,
    this.weightKg,
    this.heightCm,
    this.gender,
    this.activityLevel,
    required this.createdAt,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    int? age,
    double? weightKg,
    double? heightCm,
    String? gender,
    String? activityLevel,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'gender': gender,
      'activityLevel': activityLevel,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      age: json['age'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      gender: json['gender'] as String?,
      activityLevel: json['activityLevel'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() => 'AppUser(id: $id, name: $name, email: $email)';
}
