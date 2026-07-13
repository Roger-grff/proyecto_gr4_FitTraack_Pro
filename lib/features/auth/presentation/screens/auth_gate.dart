import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_provider.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_state.dart';
import 'package:proyecto_gr4/features/tracking/presentation/screens/home_screen.dart';
import 'login_screen.dart';

/// Centralized auth navigation gate.
///
/// Listens to [authProvider] and renders the appropriate screen:
/// - `authenticated` → [HomeScreen]
/// - `unauthenticated` / `error` → [LoginScreen]
/// - `initial` / `loading` → centered loading indicator
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    switch (authState.status) {
      case AuthStatus.authenticated:
        return const HomeScreen();

      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginScreen();

      case AuthStatus.initial:
      case AuthStatus.loading:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
    }
  }
}
