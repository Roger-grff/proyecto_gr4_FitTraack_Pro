import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/features/auth/domain/app_user.dart';
import 'package:proyecto_gr4/features/profile/data/models/update_profile_request.dart';
import 'package:proyecto_gr4/features/profile/presentation/controllers/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final AppUser currentUser;

  const EditProfileScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  String? _gender;
  String? _activityLevel;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _ageController = TextEditingController(text: widget.currentUser.age?.toString() ?? '');
    _weightController = TextEditingController(text: widget.currentUser.weightKg?.toString() ?? '');
    _heightController = TextEditingController(text: widget.currentUser.heightCm?.toString() ?? '');
    _gender = widget.currentUser.gender;
    _activityLevel = widget.currentUser.activityLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    return name != widget.currentUser.name ||
           age != widget.currentUser.age ||
           weight != widget.currentUser.weightKg ||
           height != widget.currentUser.heightCm ||
           _gender != widget.currentUser.gender ||
           _activityLevel != widget.currentUser.activityLevel;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) return;

    setState(() {
      _isSaving = true;
    });

    final request = UpdateProfileRequest(
      name: _nameController.text.trim() != widget.currentUser.name ? _nameController.text.trim() : null,
      age: int.tryParse(_ageController.text) != widget.currentUser.age ? int.tryParse(_ageController.text) : null,
      weightKg: double.tryParse(_weightController.text) != widget.currentUser.weightKg ? double.tryParse(_weightController.text) : null,
      heightCm: double.tryParse(_heightController.text) != widget.currentUser.heightCm ? double.tryParse(_heightController.text) : null,
      gender: _gender != widget.currentUser.gender ? _gender : null,
      activityLevel: _activityLevel != widget.currentUser.activityLevel ? _activityLevel : null,
    );

    try {
      await ref.read(profileProvider.notifier).updateProfile(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    enabled: !_isSaving,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Requerido';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          decoration: const InputDecoration(
                            labelText: 'Edad (años)',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          enabled: !_isSaving,
                          validator: (val) {
                            if (val != null && val.isNotEmpty) {
                              final p = int.tryParse(val);
                              if (p == null || p <= 0) return 'Inválida';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                            prefixIcon: Icon(Icons.monitor_weight_outlined),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: !_isSaving,
                          validator: (val) {
                            if (val != null && val.isNotEmpty) {
                              final p = double.tryParse(val);
                              if (p == null || p <= 0) return 'Inválido';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Altura (cm)',
                      prefixIcon: Icon(Icons.height_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isSaving,
                    validator: (val) {
                      if (val != null && val.isNotEmpty) {
                        final p = double.tryParse(val);
                        if (p == null || p <= 0) return 'Inválida';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      prefixIcon: Icon(Icons.wc_outlined),
                    ),
                    value: _gender,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Masculino')),
                      DropdownMenuItem(value: 'female', child: Text('Femenino')),
                      DropdownMenuItem(value: 'other', child: Text('Otro')),
                    ],
                    onChanged: _isSaving ? null : (val) {
                      setState(() {
                        _gender = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Nivel de actividad',
                      prefixIcon: Icon(Icons.directions_run_outlined),
                    ),
                    value: _activityLevel,
                    items: const [
                      DropdownMenuItem(value: 'sedentary', child: Text('Sedentario')),
                      DropdownMenuItem(value: 'light', child: Text('Ligero')),
                      DropdownMenuItem(value: 'moderate', child: Text('Moderado')),
                      DropdownMenuItem(value: 'active', child: Text('Activo')),
                      DropdownMenuItem(value: 'very_active', child: Text('Muy activo')),
                    ],
                    onChanged: _isSaving ? null : (val) {
                      setState(() {
                        _activityLevel = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: widget.currentUser.email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    enabled: false,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: (_isSaving || !_hasChanges) ? null : _save,
                    child: _isSaving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                              SizedBox(width: 10),
                              Text('Guardando perfil...'),
                            ],
                          )
                        : const Text('Guardar cambios'),
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
