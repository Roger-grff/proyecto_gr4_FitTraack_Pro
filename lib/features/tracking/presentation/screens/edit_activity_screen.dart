import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/data/models/update_activity_request.dart';
import 'package:proyecto_gr4/features/tracking/data/activity_service_provider.dart';
import 'package:proyecto_gr4/features/tracking/domain/activity_type.dart';
import 'package:proyecto_gr4/features/tracking/presentation/utils/activity_type_ui.dart';

class EditActivityScreen extends ConsumerStatefulWidget {
  final BackendActivity activity;

  const EditActivityScreen({super.key, required this.activity});

  @override
  ConsumerState<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends ConsumerState<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late ActivityType _selectedType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.activity.title);
    _descriptionController = TextEditingController(text: widget.activity.description);
    _selectedType = ActivityType.tryFromApiValue(widget.activity.type) ?? ActivityType.running;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    final titleChanged = _titleController.text.trim() != widget.activity.title;
    final descriptionChanged = _descriptionController.text.trim() != widget.activity.description;
    final typeChanged = _selectedType.apiValue != widget.activity.type;
    return titleChanged || descriptionChanged || typeChanged;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final request = UpdateActivityRequest(
        title: _titleController.text.trim() != widget.activity.title ? _titleController.text.trim() : null,
        description: _descriptionController.text.trim() != widget.activity.description ? _descriptionController.text.trim() : null,
        type: _selectedType.apiValue != widget.activity.type ? _selectedType.apiValue : null,
      );

      await ref.read(activityServiceProvider).updateActivity(widget.activity.id, request);
      
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error inesperado al actualizar la actividad.')),
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
    final hasChanges = _hasChanges();
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Actividad'),
          actions: [
            TextButton(
              onPressed: (_isSaving || !hasChanges) ? null : _saveChanges,
              child: const Text('Guardar'),
            )
          ],
        ),
        body: _isSaving
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Guardando cambios...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El título no puede estar vacío';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      const Text('Tipo de actividad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ...ActivityType.values.map((type) => RadioListTile<ActivityType>(
                        title: Row(
                          children: [
                            Icon(type.icon, color: type.color),
                            const SizedBox(width: 8),
                            Text(type.displayName),
                          ],
                        ),
                        value: type,
                        groupValue: _selectedType,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      )),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: (_isSaving || !hasChanges) ? null : _saveChanges,
                        child: const Text('Guardar cambios'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
