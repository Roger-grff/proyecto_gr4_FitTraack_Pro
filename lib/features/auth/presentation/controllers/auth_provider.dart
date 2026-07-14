
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/features/auth/data/auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // Start session check asynchronously after initialization
    Future.microtask(() => _checkInitialSession());
    return AuthState.initial();
  }

  /// Checks local JWT token and calls backend /me to restore session
  Future<void> _checkInitialSession() async {
    // Keep loading state
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error al verificar el estado de la sesión.',
        clearUser: true,
      );
    }
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await _repository.signIn(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Sign up with email, password, and name
  Future<void> signUp(String email, String password, String nombre) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await _repository.signUp(email, password, nombre);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _repository.signOut();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Reset password via email (Fase 1)
  Future<void> requestPasswordRecovery(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _repository.requestPasswordRecovery(email);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Validate recovery token (Fase 2)
  Future<void> validateRecoveryToken(String token) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _repository.validateRecoveryToken(token);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      throw e; // Rethrow to let the UI know it failed
    }
  }

  /// Set new password (Fase 3)
  Future<void> setNewPassword(String token, String password, String confirmPassword) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _repository.setNewPassword(token, password, confirmPassword);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      throw e;
    }
  }

  /// Clear current error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Riverpod Provider for AuthNotifier
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
