import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/features/tracking/data/models/activity_detail_result.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/presentation/utils/activity_type_ui.dart';
import 'package:proyecto_gr4/features/tracking/presentation/screens/edit_activity_screen.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_track_point.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/activity_detail_controller.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_track_point.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/activity_detail_controller.dart';

import 'package:proyecto_gr4/features/tracking/data/activity_service_provider.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/activities_controller.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  final String activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  ConsumerState<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  bool _isDeleting = false;

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final m = twoDigits(duration.inMinutes.remainder(60));
    final s = twoDigits(duration.inSeconds.remainder(60));
    final h = duration.inHours;
    if (h > 0) {
      return '${twoDigits(h)}:$m:$s';
    }
    return '$m:$s';
  }

  Future<void> _openEditScreen(BackendActivity activity) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditActivityScreen(activity: activity),
      ),
    );

    if (result == true && mounted) {
      ref.invalidate(activitiesProvider);
      ref.invalidate(activityDetailProvider(widget.activityId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actividad actualizada correctamente.')),
      );
    }
  }

  Future<void> _deleteActivity() async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);

    try {
      await ref.read(activityServiceProvider).deleteActivity(widget.activityId);
      
      ref.invalidate(activitiesProvider);
      ref.invalidate(activityDetailProvider(widget.activityId));
      
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      
      String msg = 'No se pudo eliminar la actividad.';
      if (e.statusCode == 401) {
        msg = 'Tu sesión expiró. Vuelve a iniciar sesión.';
      } else if (e.statusCode == 403) {
        msg = 'No tienes permiso para eliminar esta actividad.';
      } else if (e.statusCode == 404) {
        msg = 'La actividad ya no existe.';
        ref.invalidate(activitiesProvider); // Invalidar localmente para que no aparezca
      } else if (e.statusCode == 500) {
        msg = 'No se pudo eliminar la actividad en este momento.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _isDeleting = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la actividad. Revisa tu conexión.')),
      );
      setState(() => _isDeleting = false);
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (context) {
        return AlertDialog(
          title: const Text('¿Eliminar actividad?'),
          content: const Text('Esta acción eliminará permanentemente la actividad y su recorrido. No se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      _deleteActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(activityDetailProvider(widget.activityId));
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isDeleting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Actividad'),
        ),
        body: _isDeleting
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Eliminando actividad...'),
                  ],
                ),
              )
            : detailAsync.when(
                data: (result) => _buildDetail(context, result, theme, ref),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error al cargar detalle', style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(activityDetailProvider(widget.activityId)),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, ActivityDetailResult result, ThemeData theme, WidgetRef ref) {
    final activity = result.activity;
    final trackPoints = result.trackPoints;

    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(activity.startedAt.toLocal());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: ActivityTypeHelper.getColor(activity.type).withValues(alpha: 0.2),
                  child: Icon(
                    ActivityTypeHelper.getIcon(activity.type),
                    color: ActivityTypeHelper.getColor(activity.type),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${ActivityTypeHelper.translate(activity.type)} • $dateStr',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      if (activity.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(activity.description, style: theme.textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map
          if (trackPoints.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
                child: Center(
                  child: Text(
                    'Esta actividad no tiene una ruta GPS disponible',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            )
          else
            _buildMap(trackPoints, theme),

          // Stats grid
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Resumen',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(theme, 'Distancia', '${activity.distanceKm.toStringAsFixed(2)} km', Icons.social_distance),
                        _buildStat(theme, 'Duración', _formatDuration(activity.durationSeconds), Icons.timer),
                        _buildStat(
                          theme, 
                          activity.type == 'running' || activity.type == 'walking' ? 'Ritmo Medio' : 'Vel. Media', 
                          activity.type == 'running' || activity.type == 'walking'
                            ? (activity.avgPace > 0 ? '${activity.avgPace.toStringAsFixed(2)} min/km' : '0.0 min/km')
                            : (activity.avgSpeed > 0 ? '${activity.avgSpeed.toStringAsFixed(2)} km/h' : '0.0 km/h'),
                          activity.type == 'running' || activity.type == 'walking' ? ActivityTypeHelper.getIcon(activity.type) : Icons.speed,
                        ),
                      ],
                    ),
                    if (activity.caloriesBurned > 0) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStat(theme, 'Calorías', '${activity.caloriesBurned.toStringAsFixed(0)} kcal', Icons.local_fire_department, color: Colors.orange),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FilledButton.icon(
              onPressed: _isDeleting ? null : () => _openEditScreen(activity),
              icon: const Icon(Icons.edit),
              label: const Text('Editar actividad'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // Delete button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: OutlinedButton.icon(
              onPressed: _isDeleting ? null : _showDeleteConfirmation,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar actividad'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(ThemeData theme, String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppTheme.primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMap(List<BackendTrackPoint> trackPoints, ThemeData theme) {
    
    // Convert to LatLng
    final validPoints = <LatLng>[];
    for (final p in trackPoints) {
      if (p.latitude >= -90 && p.latitude <= 90 && p.longitude >= -180 && p.longitude <= 180) {
        validPoints.add(LatLng(p.latitude, p.longitude));
      }
    }

    if (validPoints.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: Text('Datos GPS inválidos')),
        ),
      );
    }

    LatLng center;
    double zoom = 14.5;

    if (validPoints.length == 1) {
      center = validPoints.first;
    } else {
      // Calculamos centro a grosso modo
      final first = validPoints.first;
      final last = validPoints.last;
      center = LatLng(
        (first.latitude + last.latitude) / 2,
        (first.longitude + last.longitude) / 2,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.gpstracker',
              ),
              if (validPoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: validPoints,
                      color: AppTheme.primaryColor,
                      strokeWidth: 6.0,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (validPoints.isNotEmpty)
                    Marker(
                      point: validPoints.first,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  if (validPoints.length > 1)
                    Marker(
                      point: validPoints.last,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
