import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/core/utils/validators.dart';
import 'package:proyecto_gr4/core/utils/app_snackbar.dart';
import 'package:proyecto_gr4/core/widgets/primary_button.dart';
import 'package:proyecto_gr4/core/widgets/app_text_field.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_provider.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_state.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).requestPasswordRecovery(
            _emailController.text.trim(),
          );
          
      // Check for errors or success
      final state = ref.read(authProvider);
      if (state.status == AuthStatus.error) {
        if (mounted) {
          AppSnackBar.showError(context, state.errorMessage ?? 'Error desconocido');
          ref.read(authProvider.notifier).clearError();
        }
      } else {
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Revisa tu correo institucional para restablecer tu contraseña');
          // Navigate to reset screen (manual token entry mode)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
          );
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
        title: const Text('Recuperar contraseña'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_reset_rounded,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¿Olvidaste tu contraseña?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa tu correo institucional y te enviaremos un código para recuperarla.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  AppTextField(
                    label: 'Correo electrónico',
                    hint: 'correo@epn.edu.ec',
                    prefixIcon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Enviar código',
                    onPressed: _submitForm,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ResetPasswordScreen(),
                              ),
                            );
                          },
                    child: Text(
                      'Ya tengo un código de recuperación',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
