import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:proyecto_gr4/core/constants/api_constants.dart';
import 'package:proyecto_gr4/features/auth/domain/app_user.dart';

class AuthService {
  /// POST /api/auth/login
  /// Returns a map containing the token and the parsed AppUser
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = AppUser.fromJson(userJson);
      
      return {
        'token': token,
        'user': user,
      };
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error al iniciar sesión');
    }
  }

  /// POST /api/auth/register
  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final response = await http.post(
      Uri.parse(ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = AppUser.fromJson(userJson);
      
      return {
        'token': token,
        'user': user,
      };
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error al registrar usuario');
    }
  }

  /// GET /api/auth/me
  /// Uses the provided JWT token to get the current user profile.
  Future<AppUser> getMe(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.me),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AppUser.fromJson(data);
    } else {
      throw Exception('Sesión expirada o token inválido');
    }
  }

  /// POST /api/auth/recuperarpassword
  Future<void> recoverPassword(String email) async {
    final response = await http.post(
      Uri.parse(ApiConstants.recover),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error al intentar recuperar la contraseña');
    }
  }

  /// GET /api/auth/recuperarpassword/{token}
  Future<void> validateRecoveryToken(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.recover}/$token'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Token inválido o expirado');
    }
  }

  /// POST /api/auth/nuevopassword/{token}
  Future<void> resetPassword(String token, String password, String confirmPassword) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.newPassword}/$token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'password': password,
        'confirmpassword': confirmPassword,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error al cambiar la contraseña');
    }
  }
}
