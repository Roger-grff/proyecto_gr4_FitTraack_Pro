import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proyecto_gr4/features/auth/domain/app_user.dart';
import 'auth_service.dart';

// Riverpod Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Riverpod Provider for FlutterSecureStorage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Riverpod Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepository(authService, secureStorage);
});

/// Business logic layer over AuthService (REST API).
/// Handles error mapping, JWT token persistence securely using FlutterSecureStorage.
class AuthRepository {
  final AuthService _authService;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'jwt_token';

  AuthRepository(this._authService, this._secureStorage);

  // ---------------------------------------------------------------------------
  // Authentication Methods
  // ---------------------------------------------------------------------------

  /// Sign in with email and password. Returns AppUser on success and saves JWT.
  Future<AppUser> signIn(String email, String password) async {
    try {
      final response = await _authService.login(email, password);
      
      final token = response['token'] as String;
      final user = response['user'] as AppUser;

      // Save token securely
      await _secureStorage.write(key: _tokenKey, value: token);

      return user;
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Sign up, receive token, save it securely and return AppUser.
  Future<AppUser> signUp(String email, String password, String name) async {
    try {
      final response = await _authService.register(email, password, name);
      
      final token = response['token'] as String;
      final user = response['user'] as AppUser;

      // Save token securely
      await _secureStorage.write(key: _tokenKey, value: token);

      return user;
    } catch (e) {
      throw Exception('Error al crear la cuenta: $e');
    }
  }

  /// Sign out current user. Deletes JWT token from storage.
  Future<void> signOut() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Send password reset email via API. (Fase 1)
  Future<void> requestPasswordRecovery(String email) async {
    try {
      await _authService.recoverPassword(email);
    } catch (e) {
      throw Exception('Error al enviar correo de recuperación: $e');
    }
  }

  /// Validate recovery token (Fase 2)
  Future<void> validateRecoveryToken(String token) async {
    try {
      await _authService.validateRecoveryToken(token);
    } catch (e) {
      throw Exception('Token inválido o expirado: $e');
    }
  }

  /// Set new password (Fase 3)
  Future<void> setNewPassword(String token, String password, String confirmPassword) async {
    try {
      await _authService.resetPassword(token, password, confirmPassword);
    } catch (e) {
      throw Exception('Error al cambiar contraseña: $e');
    }
  }

  /// Get current user profile by checking saved JWT and hitting /api/auth/me
  Future<AppUser?> getCurrentUser() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      
      if (token == null || token.isEmpty) {
        return null; // No token saved, user is unauthenticated
      }

      // Verify token with backend
      final user = await _authService.getMe(token);
      return user;
    } catch (e) {
      // If verification fails (e.g., token expired), clear local storage
      await _secureStorage.delete(key: _tokenKey);
      return null;
    }
  }
}
