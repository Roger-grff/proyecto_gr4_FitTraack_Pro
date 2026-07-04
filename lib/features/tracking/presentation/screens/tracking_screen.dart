import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/tracking_controller.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/tracking_state.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/timer_controller.dart';
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

    // Watch status and navigate to summary once completed
    ref.listen<TrackingState>(trackingProvider, (previous, next) {
      if (next.status == TrackingStatus.finished && next.finishedSession != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SummaryScreen(session: next.finishedSession!),
          ),
        );
      }
      
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
    } else if (status == TrackingStatus.paused) {
      return Row(
        children: [
          // Resume button
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
          const SizedBox(width: 12),
          // Finish button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showNamingDialog(context, notifier),
              icon: const Icon(Icons.stop, color: Colors.white),
              label: const Text('FINALIZAR', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // Dialog to select/input a custom name before saving the session
  void _showNamingDialog(BuildContext context, TrackingNotifier notifier) {
    String selectedCategory = 'Carrera matutina';
    final customNameController = TextEditingController();
    bool useCustomName = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Force making a choice
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    const Text('Elige una etiqueta para guardar tu recorrido:'),
                    const SizedBox(height: 12),
                    
                    // Predefined options
                    RadioListTile<String>(
                      title: const Text('Carrera matutina'),
                      value: 'Carrera matutina',
                      groupValue: useCustomName ? null : selectedCategory,
                      onChanged: (value) {
                        setDialogState(() {
                          useCustomName = false;
                          selectedCategory = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Ciclismo de ruta'),
                      value: 'Ciclismo de ruta',
                      groupValue: useCustomName ? null : selectedCategory,
                      onChanged: (value) {
                        setDialogState(() {
                          useCustomName = false;
                          selectedCategory = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Caminata'),
                      value: 'Caminata',
                      groupValue: useCustomName ? null : selectedCategory,
                      onChanged: (value) {
                        setDialogState(() {
                          useCustomName = false;
                          selectedCategory = value!;
                        });
                      },
                    ),
                    RadioListTile<bool>(
                      title: const Text('Nombre personalizado'),
                      value: true,
                      groupValue: useCustomName,
                      onChanged: (value) {
                        setDialogState(() {
                          useCustomName = value!;
                        });
                      },
                    ),
                    
                    if (useCustomName) ...[
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
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR'),
                ),
                TextButton(
                  onPressed: () {
                    // Decide which name to save
                    String finalTitle = selectedCategory;
                    if (useCustomName) {
                      finalTitle = customNameController.text.trim();
                      if (finalTitle.isEmpty) {
                        finalTitle = 'Actividad Personalizada';
                      }
                    }
                    
                    Navigator.pop(context); // Close dialog
                    notifier.finishActivity(finalTitle); // Complete tracking
                  },
                  child: const Text(
                    'GUARDAR Y FINALIZAR',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
