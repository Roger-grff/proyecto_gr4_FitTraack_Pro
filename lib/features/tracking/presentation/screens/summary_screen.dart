import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/features/tracking/domain/activity_session.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/tracking_controller.dart';
import 'package:intl/intl.dart';

class SummaryScreen extends ConsumerWidget {
  final ActivitySession session;

  const SummaryScreen({
    super.key,
    required this.session,
  });

  // Helper to format Duration to readable text
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = duration.inHours;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd MMMM yyyy, hh:mm a', 'es').format(session.startTime);

    // Calculate map center or midpoint for initial position
    LatLng mapCenter = const LatLng(4.7110, -74.0721);
    double zoomLevel = 14.0;
    
    if (session.routePoints.isNotEmpty) {
      final first = session.routePoints.first;
      final last = session.routePoints.last;
      
      // Calculate midpoint
      mapCenter = LatLng(
        (first.latitude + last.latitude) / 2,
        (first.longitude + last.longitude) / 2,
      );
      
      // Select zoom level based on length of points (approximation)
      if (session.stats.distance > 5000) {
        zoomLevel = 12.0;
      } else if (session.stats.distance > 2000) {
        zoomLevel = 13.0;
      } else {
        zoomLevel = 14.5;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Actividad', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, // Force home navigation through button
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Completion Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '¡Actividad Completada!',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Center(
                child: Text(
                  dateStr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. Static Map Preview using OpenStreetMap (Interactive disabled)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 220,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: zoomLevel,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.gpstracker',
                      ),
                      PolylineLayer(
                        polylines: session.routePoints.isEmpty
                            ? <Polyline>[]
                            : <Polyline>[
                                Polyline(
                                  points: session.routePoints
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
                          if (session.routePoints.isNotEmpty) ...[
                            Marker(
                              point: LatLng(
                                session.routePoints.first.latitude,
                                session.routePoints.first.longitude,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.green,
                                size: 40,
                              ),
                            ),
                            Marker(
                              point: LatLng(
                                session.routePoints.last.latitude,
                                session.routePoints.last.longitude,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Stats Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildSummaryCard(
                    context,
                    'Distancia Total',
                    '${session.stats.distanceKm.toStringAsFixed(2)} km',
                    Icons.social_distance,
                    Colors.blue,
                  ),
                  _buildSummaryCard(
                    context,
                    'Tiempo Transcurrido',
                    _formatDuration(session.stats.duration),
                    Icons.timer,
                    Colors.orange,
                  ),
                  _buildSummaryCard(
                    context,
                    'Velocidad Promedio',
                    '${session.stats.averageSpeedKmH.toStringAsFixed(1)} km/h',
                    Icons.av_timer,
                    Colors.teal,
                  ),
                  _buildSummaryCard(
                    context,
                    'Velocidad Máxima',
                    '${session.stats.maxSpeedKmH.toStringAsFixed(1)} km/h',
                    Icons.speed,
                    Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 4. Return Home Button
              ElevatedButton(
                onPressed: () {
                  ref.read(trackingProvider.notifier).reset();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'VOLVER A INICIO',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
