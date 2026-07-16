import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_gr4/features/profile/data/models/update_profile_request.dart';

void main() {
  group('UpdateProfileRequest Tests', () {
    test('1. Permite crear request parcial con solo algunos campos', () {
      final req = UpdateProfileRequest(name: 'Juan', age: 30);
      expect(req.toJson(), {'name': 'Juan', 'age': 30});
    });

    test('2. Rechaza request vacio', () {
      expect(() => UpdateProfileRequest(), throwsArgumentError);
    });

    test('3. Aplica trim al nombre y rechaza vacios', () {
      final req = UpdateProfileRequest(name: '  Juan  ');
      expect(req.toJson()['name'], 'Juan');

      expect(() => UpdateProfileRequest(name: '   '), throwsArgumentError);
    });

    test('4. Valida gender', () {
      expect(() => UpdateProfileRequest(gender: 'unknown'), throwsArgumentError);
      final req = UpdateProfileRequest(gender: 'other');
      expect(req.toJson()['gender'], 'other');
    });

    test('5. Valida activityLevel', () {
      expect(() => UpdateProfileRequest(activityLevel: 'super_active'), throwsArgumentError);
      final req = UpdateProfileRequest(activityLevel: 'moderate');
      expect(req.toJson()['activityLevel'], 'moderate');
    });

    test('6. Valida numeros', () {
      expect(() => UpdateProfileRequest(age: -5), throwsArgumentError);
      expect(() => UpdateProfileRequest(weightKg: 0), throwsArgumentError);
      expect(() => UpdateProfileRequest(heightCm: -10), throwsArgumentError);
    });
  });
}
