import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/tracking_controller.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/tracking_state.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/timer_controller.dart';
import 'package:proyecto_gr4/features/tracking/domain/activity_type.dart';
import 'package:proyecto_gr4/features/tracking/presentation/utils/activity_type_ui.dart';
import 'summary_screen.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final MapController _mapController = MapController();
  bool _autoCenter = true;
  bool _gpsActiveAlertShown = false;

  // Format Duration helper
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = duration.inHours;
    if (hours > 0) {
      return '${twoDigits(hours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    final duration = ref.watch(timerProvider);
    final theme = Theme.of(context);

    // Watch status
    ref.listen<TrackingState>(trackingProvider, (previous, next) {
      // Dynamic GPS status alert message that appears and disappears automatically
      if (next.routePoints.isNotEmpty && !_gpsActiveAlertShown && next.status == TrackingStatus.tracking) {
        setState(() {
          _gpsActiveAlertShown = true;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Señal GPS Activa! Recorrido iniciado.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Auto-center the camera when a new location point arrives
      if (_autoCenter && next.routePoints.isNotEmpty) {
        final lastPoint = next.routePoints.last;
        _mapController.move(
          LatLng(lastPoint.latitude, lastPoint.longitude),
          _mapController.camera.zoom,
        );
      }
    });

    // Default initial location if points are empty (e.g. Bogota center)
    LatLng initialLatLng = const LatLng(4.7110, -74.0721);
    if (trackingState.routePoints.isNotEmpty) {
      initialLatLng = LatLng(
        trackingState.routePoints.last.latitude,
        trackingState.routePoints.last.longitude,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          trackingState.status == TrackingStatus.paused ? 'Actividad Pausada' : 'Grabando Recorrido',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false, // Prevent returning via gesture, force using buttons
      ),
      body: Column(
        children: [
          // 1. OpenStreetMap View (Top 60-65%)
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialLatLng,
                    initialZoom: 16.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onPositionChanged: (position, hasGesture) {
                      // If user manually drags/pans the map, disable auto-centering
                      if (hasGesture && _autoCenter) {
                        setState(() {
                          _autoCenter = false;
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.gpstracker',
                    ),
                    PolylineLayer(
                      polylines: trackingState.routePoints.isEmpty
                          ? <Polyline>[]
                          : <Polyline>[
                              Polyline(
                                points: trackingState.routePoints
                                    .map((point) => LatLng(point.latitude, point.longitude))
                                    .toList(),
                                color: AppTheme.primaryColor,
                                strokeWidth: 6.0,
                                strokeCap: StrokeCap.round,
                                strokeJoin: StrokeJoin.round,
                              ),
                            ],
                    ),
                    MarkerLayer(
                      markers: [
                        if (trackingState.routePoints.isNotEmpty) ...[
                          // Start point pin marker
                          Marker(
                            point: LatLng(
                              trackingState.routePoints.first.latitude,
                              trackingState.routePoints.first.longitude,
                            ),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                          // Current location dot marker
                          Marker(
                            point: LatLng(
                              trackingState.routePoints.last.latitude,
                              trackingState.routePoints.last.longitude,
                            ),
                            width: 32,
                            height: 32,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
                // Auto-center Floating Button
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      setState(() {
                        _autoCenter = true;
                      });
                      if (trackingState.routePoints.isNotEmpty) {
                        final last = trackingState.routePoints.last;
                        _mapController.move(
                          LatLng(last.latitude, last.longitude),
                          _mapController.camera.zoom,
                        );
                      }
                    },
                    backgroundColor: _autoCenter ? AppTheme.primaryColor : theme.cardColor,
                    child: Icon(
                      Icons.my_location,
                      color: _autoCenter ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // Dynamic GPS Signal alert banner at the top of the map (appears/disappears automatically)
                if (trackingState.routePoints.isEmpty && trackingState.status == TrackingStatus.tracking)
                  Positioned(
                    top: 16,
                    left: 24,
                    right: 24,
                    child: Card(
                      color: Colors.amber[800]?.withOpacity(0.95),
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Buscando señal GPS real...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Statistics & Controls Panel (Bottom 35-40%)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Timer displaying duration at top of stats
                  Text(
                    _formatDuration(duration),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  
                  const Divider(height: 8),

                  // Three column grid of stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        'Distancia',
                        '${trackingState.stats.distanceKm.toStringAsFixed(2)} km',
                        Icons.social_distance,
                      ),
                      _buildStatItem(
                        context,
                        'Vel. Actual',
                        '${trackingState.stats.currentSpeedKmH.toStringAsFixed(1)} km/h',
                        Icons.speed,
                      ),
                      _buildStatItem(
                        context,
                        'Vel. Promedio',
                        '${trackingState.stats.averageSpeedKmH.toStringAsFixed(1)} km/h',
                        Icons.av_timer,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Controls buttons (Pause, Resume, Finish)
                  _buildControls(context, ref, trackingState.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, WidgetRef ref, TrackingStatus status) {
    final notifier = ref.read(trackingProvider.notifier);
    final isSaving = ref.watch(trackingProvider).isSavingActivity;

    if (status == TrackingStatus.tracking) {
      return Row(
        children: [
          // Pause button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => notifier.pauseActivity(),
              icon: const Icon(Icons.pause, color: Colors.white),
              label: const Text('PAUSAR', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else if (status == TrackingStatus.paused || status == TrackingStatus.finished) {
      return Row(
        children: [
          // Resume button
          if (status == TrackingStatus.paused && !isSaving)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => notifier.resumeActivity(),
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('REANUDAR', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          if (status == TrackingStatus.paused && !isSaving) const SizedBox(width: 12),
          // Finish button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : () => _showNamingDialog(context, notifier),
              icon: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Icon(Icons.stop, color: Colors.white),
              label: Text(isSaving ? 'GUARDANDO...' : 'FINALIZAR', style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showErrorDialog(BuildContext context, WidgetRef ref, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final isSaving = ref.watch(trackingProvider).isSavingActivity;
            
            return AlertDialog(
              title: const Text('Error al guardar', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message),
                  if (isSaving) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    const Text('Reintentando...'),
                  ]
                ],
              ),
              actions: [
                if (!isSaving)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('CANCELAR'),
                  ),
                if (!isSaving)
                  TextButton(
                    onPressed: () async {
                      try {
                        final result = await ref.read(trackingProvider.notifier).retryPendingActivitySave();
                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SummaryScreen(session: result.localSession),
                          ),
                        );
                      } catch (e) {
                        // El error se actualiza en el provider o lo atrapamos aquí para mostrarlo en el snackbar
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Falló el reintento: ${ref.read(trackingProvider).saveActivityError ?? e.toString()}'))
                        );
                      }
                    },
                    child: const Text('REINTENTAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            );
          }
        );
      }
    );
  }

  // Dialog to select/input a custom name before saving the session
  void _showNamingDialog(BuildContext context, TrackingNotifier notifier) {
    ActivityType selectedCategory = ActivityType.running;
    final customNameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Force making a choice
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final isSaving = ref.watch(trackingProvider).isSavingActivity;
            
            return AlertDialog(
              title: const Text(
                'Etiquetar Recorrido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isSaving) ...[
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 16),
                      const Center(child: Text('Guardando actividad...', style: TextStyle(fontWeight: FontWeight.bold))),
                    ] else ...[
                      const Text('Elige una etiqueta para guardar tu recorrido:'),
                      const SizedBox(height: 12),
                      
                      ...ActivityType.values.map((type) => RadioListTile<ActivityType>(
                        title: Row(
                          children: [
                            Icon(type.icon, color: type.color),
                            const SizedBox(width: 8),
                            Text(type.displayName),
                          ],
                        ),
                        value: type,
                        groupValue: selectedCategory,
                        onChanged: (value) {
                          if (value != null) {
                            selectedCategory = value;
                            (context as Element).markNeedsBuild();
                          }
                        },
                      )),
                      
                      const SizedBox(height: 8),
                      TextField(
                        controller: customNameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Ej. Trote en el parque',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                if (!isSaving)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('CANCELAR'),
                  ),
                if (!isSaving)
                  TextButton(
                    onPressed: () async {
                      String finalTitle = customNameController.text.trim();
                      if (finalTitle.isEmpty) {
                        finalTitle = selectedCategory.displayName;
                      }
                      
                      try {
                        final result = await notifier.finishAndSaveActivity(
                          title: finalTitle,
                          type: selectedCategory.apiValue,
                        );
                        if (!context.mounted) return;
                        
                        Navigator.pop(dialogContext); // Close dialog
                        
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SummaryScreen(session: result.localSession),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        _showErrorDialog(context, ref, ref.read(trackingProvider).saveActivityError ?? e.toString());
                      }
                    },
                    child: const Text(
                      'GUARDAR Y FINALIZAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            );
          }
        );
      },
    );
  }
}
