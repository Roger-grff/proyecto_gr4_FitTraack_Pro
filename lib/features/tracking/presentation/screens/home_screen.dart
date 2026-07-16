import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/features/tracking/data/tracking_repository.dart';
import 'package:proyecto_gr4/features/tracking/domain/activity_session.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/tracking_controller.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/tracking_state.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/activities_controller.dart';
import 'package:proyecto_gr4/features/tracking/presentation/widgets/backend_activity_card.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'tracking_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'package:proyecto_gr4/core/providers/settings_provider.dart';
import 'package:proyecto_gr4/core/services/weather_service.dart';
import 'package:proyecto_gr4/core/services/elevation_service.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesProvider);
    final theme = Theme.of(context);

    // If an error occurred during tracking init, show a Snackbar
    ref.listen<TrackingState>(trackingProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ref.read(trackingProvider.notifier).clearError();
              },
            ),
          ),
        );
        ref.read(trackingProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(activitiesProvider.notifier).refreshActivities();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card with Profile & App Title
                _buildHeader(context, ref),
                
                const SizedBox(height: 56),

                // Big "Iniciar actividad" button with circular progress / indicator
                _buildStartButton(context, ref),

                const SizedBox(height: 56),

                // Recent activities title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Actividades Recientes',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          ref.read(activitiesProvider.notifier).refreshActivities();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Dynamic list of recorded activities (Empty state if empty)
                _buildRecentActivitiesList(context, ref, activitiesAsync),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark 
              ? [AppTheme.darkBackground, const Color(0xFF131A30)]
              : [AppTheme.primaryColor.withOpacity(0.1), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, Corredor',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GPS Tracker Pro',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                _buildWeatherAndElevationWidget(context, ref),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: AppTheme.primaryColor, size: 28),
                tooltip: 'Configuración',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.cardDarkBackground,
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWeatherAndElevationWidget(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    
    Future<Map<String, dynamic>> fetchData() async {
      double lat = -0.2186;
      double lng = -78.5085;
      
      if (!settings.useSimulation) {
        try {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 3),
            );
            lat = pos.latitude;
            lng = pos.longitude;
          }
        } catch (_) {
          // Fallback to default coordinates on error/timeout
        }
      }
      
      final results = await Future.wait([
        WeatherService().fetchWeather(lat, lng),
        ElevationService().fetchElevation(lat, lng),
      ]);
      
      return {
        'weather': results[0] as WeatherData,
        'elevation': results[1] as double,
      };
    }
    
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.2, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 6),
                Text(
                  'Cargando clima y altitud...',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final weather = snapshot.data!['weather'] as WeatherData;
        final elevation = snapshot.data!['elevation'] as double;
        
        IconData weatherIcon = Icons.wb_cloudy_outlined;
        final code = weather.weatherCode;
        if (code == 0) weatherIcon = Icons.wb_sunny;
        else if (code >= 1 && code <= 3) weatherIcon = Icons.wb_cloudy_outlined;
        else if (code == 45 || code == 48) weatherIcon = Icons.filter_drama;
        else if (code >= 51 && code <= 55) weatherIcon = Icons.grain;
        else if (code >= 61 && code <= 65) weatherIcon = Icons.beach_access;
        else if (code >= 80 && code <= 82) weatherIcon = Icons.umbrella;
        else if (code >= 95 && code <= 99) weatherIcon = Icons.thunderstorm;

        final elevationStr = settings.useMetricUnits
            ? '${elevation.toStringAsFixed(0)} msnm'
            : '${(elevation * 3.28084).toStringAsFixed(0)} pies';

        return Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              Icon(weatherIcon, size: 14, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
              Text(
                '${weather.temperature.toStringAsFixed(0)}°C',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '•',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3), fontSize: 11),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.filter_hdr, size: 14, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
              Text(
                elevationStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStartButton(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Center(
      child: InkWell(
        onTap: () async {
          // Pre-flight check: Verify if GPS is enabled
          final repo = ref.read(trackingRepositoryProvider);
          final gpsEnabled = await repo.isGPSEnabled();
          
          if (!gpsEnabled) {
            // Show alert dialog if GPS is disabled
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(
                    'GPS Desactivado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: const Text(
                    'El GPS de tu dispositivo está apagado. Por favor, actívalo en los ajustes de tu sistema para iniciar el seguimiento del recorrido.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ENTENDIDO'),
                    ),
                  ],
                ),
              );
            }
            return;
          }

          // Show temporary "GPS Activo" alert snackbar
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('GPS Activo'),
                duration: Duration(milliseconds: 1500),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Trigger activity start
          await ref.read(trackingProvider.notifier).startActivity();
          
          // Navigate to tracking screen
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const TrackingScreen()),
            );
          }
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Text(
                'INICIAR',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'ACTIVIDAD',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesList(BuildContext context, WidgetRef ref, AsyncValue<List<BackendActivity>> activitiesAsync) {
    final theme = Theme.of(context);

    return activitiesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando actividades...'),
            ],
          ),
        ),
      ),
      error: (error, stack) {
        final message = ref.read(activitiesProvider.notifier).getErrorMessage(error);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(activitiesProvider.notifier).refreshActivities(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (activities) {
        // Empty state representation
        if (activities.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 56,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Todavía no tienes actividades registradas.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Las rutas que grabes y finalices aparecerán listadas aquí.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Dynamic list
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return BackendActivityCard(activity: activities[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
