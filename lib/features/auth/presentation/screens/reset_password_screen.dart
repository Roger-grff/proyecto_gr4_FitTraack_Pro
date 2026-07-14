import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/core/utils/validators.dart';
import 'package:proyecto_gr4/core/utils/app_snackbar.dart';
import 'package:proyecto_gr4/core/widgets/primary_button.dart';
import 'package:proyecto_gr4/core/widgets/app_text_field.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_provider.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_state.dart';
import 'package:proyecto_gr4/features/auth/presentation/screens/login_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? initialToken;

  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _tokenFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _tokenController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isTokenValidated = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken);
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      // Si recibiéramos el token por un Deep Link en el futuro, podríamos validarlo automáticamente.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateToken();
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    FocusScope.of(context).unfocus();
    if (_tokenFormKey.currentState!.validate()) {
      try {
        await ref.read(authProvider.notifier).validateRecoveryToken(_tokenController.text.trim());
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Token validado. Ya puedes crear tu nueva contraseña.');
          setState(() {
            _isTokenValidated = true;
          });
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    if (_passwordFormKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        AppSnackBar.showError(context, 'Las contraseñas no coinciden');
        return;
      }

      try {
        await ref.read(authProvider.notifier).setNewPassword(
              _tokenController.text.trim(),
              _passwordController.text,
              _confirmPasswordController.text,
            );
        if (mounted) {
          AppSnackBar.showSuccess(context, '¡Contraseña actualizada exitosamente!');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva contraseña'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.password_rounded,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  _isTokenValidated ? 'Ingresa tu nueva contraseña' : 'Valida tu código',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isTokenValidated
                      ? 'Asegúrate de usar una contraseña segura y que no olvides.'
                      : 'Ingresa el código que recibiste en tu correo para continuar.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                if (!_isTokenValidated) ...[
                  Form(
                    key: _tokenFormKey,
                    child: AppTextField(
                      label: 'Código de recuperación (Token)',
                      hint: 'Pega el código aquí...',
                      prefixIcon: Icons.key_outlined,
                      controller: _tokenController,
                      validator: (value) => value != null && value.isNotEmpty ? null : 'El código es requerido',
                      enabled: !isLoading,
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Validar código',
                    onPressed: _validateToken,
                    isLoading: isLoading,
                  ),
                ] else ...[
                  Form(
                    key: _passwordFormKey,
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'Nueva contraseña',
                          hint: 'Ejemplo1@',
                          prefixIcon: Icons.lock_outline_rounded,
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: Validators.validatePassword,
                          enabled: !isLoading,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'Confirmar nueva contraseña',
                          hint: 'Ejemplo1@',
                          prefixIcon: Icons.lock_reset_rounded,
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Confirma tu contraseña';
                            if (val != _passwordController.text) return 'Las contraseñas no coinciden';
                            return null;
                          },
                          enabled: !isLoading,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Cambiar contraseña',
                    onPressed: _resetPassword,
                    isLoading: isLoading,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
