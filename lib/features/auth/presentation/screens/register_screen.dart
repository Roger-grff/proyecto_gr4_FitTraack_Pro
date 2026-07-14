import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/core/utils/validators.dart';
import 'package:proyecto_gr4/core/utils/app_snackbar.dart';
import 'package:proyecto_gr4/core/widgets/primary_button.dart';
import 'package:proyecto_gr4/core/widgets/app_text_field.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_provider.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_state.dart';
import 'package:proyecto_gr4/features/tracking/presentation/screens/home_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _submitForm() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        AppSnackBar.showError(context, 'Las contraseñas no coinciden');
        return;
      }

      await ref.read(authProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
      
      // We check state directly because AuthGate will rebuild and navigate to Home automatically
      // when AuthStatus becomes authenticated. However, RegisterScreen is pushed on top of AuthGate.
      // We should pop it if authenticated, so AuthGate's HomeScreen becomes visible, or pushReplacement.
      
      final state = ref.read(authProvider);
      if (state.status == AuthStatus.authenticated) {
        if (mounted) {
          AppSnackBar.showSuccess(context, '¡Cuenta creada con éxito!');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
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

    // Listen for errors
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        AppSnackBar.showError(context, next.errorMessage!);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
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
                  // Logo
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  
                  // Header
                  Text(
                    '¡Únete a FitTrack Pro!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea una cuenta para registrar tu progreso.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Name Field
                  AppTextField(
                    label: 'Nombre completo',
                    hint: 'Ej. Juan Pérez',
                    prefixIcon: Icons.person_outline,
                    controller: _nameController,
                    focusNode: _nameFocus,
                    nextFocusNode: _emailFocus,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  AppTextField(
                    label: 'Correo electrónico',
                    hint: 'ejemplo@correo.com',
                    prefixIcon: Icons.email_outlined,
                    controller: _emailController,
                    focusNode: _emailFocus,
                    nextFocusNode: _passwordFocus,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  AppTextField(
                    label: 'Contraseña',
                    hint: 'Mínimo 6 caracteres',
                    prefixIcon: Icons.lock_outline_rounded,
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    nextFocusNode: _confirmPasswordFocus,
                    obscureText: _obscurePassword,
                    validator: Validators.validatePassword,
                    enabled: !isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password Field
                  AppTextField(
                    label: 'Confirmar contraseña',
                    hint: 'Mínimo 6 caracteres',
                    prefixIcon: Icons.lock_reset_rounded,
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Confirma tu contraseña';
                      }
                      if (val != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                    enabled: !isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Register Button
                  PrimaryButton(
                    text: 'Crear cuenta',
                    onPressed: _submitForm,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes una cuenta?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        child: Text(
                          'Iniciar sesión',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
