import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/core/providers/settings_provider.dart';
import 'package:proyecto_gr4/core/services/weather_service.dart';
import 'package:proyecto_gr4/core/services/elevation_service.dart';
import 'package:proyecto_gr4/core/services/geocoding_service.dart';
import 'package:proyecto_gr4/core/services/firebase_service.dart';
import 'package:proyecto_gr4/features/tracking/data/tracking_repository.dart';
import 'package:geolocator/geolocator.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _weightController = TextEditingController();
  final _weatherService = WeatherService();
  final _elevationService = ElevationService();
  final _geocodingService = GeocodingService();

  // API Testing states
  bool _testingAPIs = false;
  WeatherData? _weatherResult;
  double? _elevationResult;
  String? _addressResult;
  String? _apiError;
  double? _testLat;
  double? _testLng;

  @override
  void initState() {
    super.initState();
    // Initialize weight input controller with saved value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedWeight = ref.read(settingsProvider).userWeight;
      _weightController.text = savedWeight.toStringAsFixed(1);
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  // Handle API integration testing
  Future<void> _runAPIsTest() async {
    setState(() {
      _testingAPIs = true;
      _apiError = null;
      _weatherResult = null;
      _elevationResult = null;
      _addressResult = null;
    });

    try {
      double lat;
      double lng;

      final isSimulation = ref.read(settingsProvider).useSimulation;
      if (isSimulation) {
        // Quito, Ecuador coordinates (EPN ESFOT) for simulated testing
        lat = -0.2186;
        lng = -78.5085;
      } else {
        // Check real GPS permissions and location
        final repo = ref.read(trackingRepositoryProvider);
        final gpsEnabled = await repo.isGPSEnabled();
        if (!gpsEnabled) {
          throw Exception('El servicio de GPS está desactivado. Actívalo para realizar la prueba.');
        }

        await repo.checkAndRequestPermissions();
        
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
        lat = position.latitude;
        lng = position.longitude;
      }

      setState(() {
        _testLat = lat;
        _testLng = lng;
      });

      // Run calls concurrently
      final results = await Future.wait([
        _weatherService.fetchWeather(lat, lng),
        _elevationService.fetchElevation(lat, lng),
        _geocodingService.reverseGeocode(lat, lng),
      ]);

      setState(() {
        _weatherResult = results[0] as WeatherData;
        _elevationResult = results[1] as double;
        _addressResult = results[2] as String;
      });
    } catch (e) {
      setState(() {
        _apiError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _testingAPIs = false;
      });
    }
  }

  // Get icon representing the weather
  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code >= 1 && code <= 3) return Icons.wb_cloudy_outlined;
    if (code == 45 || code == 48) return Icons.filter_drama;
    if (code >= 51 && code <= 55) return Icons.grain;
    if (code >= 61 && code <= 65) return Icons.beach_access;
    if (code >= 80 && code <= 82) return Icons.umbrella;
    if (code >= 95 && code <= 99) return Icons.thunderstorm;
    return Icons.wb_cloudy;
  }

  // Map theme mode to readable Spanish text
  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Theme Configuration Section
              _buildSectionTitle('Apariencia y Tema'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tema de la App',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Tema actual: ${_themeModeLabel(settings.themeMode)}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          DropdownButton<ThemeMode>(
                            value: settings.themeMode,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                            items: ThemeMode.values.map((ThemeMode mode) {
                              return DropdownMenuItem<ThemeMode>(
                                value: mode,
                                child: Text(_themeModeLabel(mode)),
                              );
                            }).toList(),
                            onChanged: (ThemeMode? newMode) {
                              if (newMode != null) {
                                ref.read(settingsProvider.notifier).setThemeMode(newMode);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. User Preferences Section
              _buildSectionTitle('Preferencias de Actividad'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      // Units switch
                      SwitchListTile(
                        title: const Text('Unidades Métricas', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          settings.useMetricUnits ? 'Kilómetros y Metros' : 'Millas y Pies',
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                        secondary: const Icon(Icons.square_foot, color: AppTheme.primaryColor),
                        value: settings.useMetricUnits,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (bool value) {
                          ref.read(settingsProvider.notifier).toggleUnitSystem(value);
                        },
                      ),
                      const Divider(indent: 56, endIndent: 16),
                      // Simulation switch
                      SwitchListTile(
                        title: const Text('Simulador GPS', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          settings.useSimulation 
                              ? 'Generando coordenadas de ruta ficticia' 
                              : 'Usando coordenadas de satélites GPS reales',
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                        secondary: const Icon(Icons.alt_route, color: AppTheme.primaryColor),
                        value: settings.useSimulation,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (bool value) {
                          ref.read(settingsProvider.notifier).toggleSimulation(value);
                        },
                      ),
                      const Divider(indent: 56, endIndent: 16),
                      // Weight input field
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.monitor_weight_outlined, color: AppTheme.primaryColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Peso Corporal',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Usado para el cálculo de calorías',
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  suffixText: settings.useMetricUnits ? 'kg' : 'lb',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: const OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                onChanged: (value) {
                                  final doubleWeight = double.tryParse(value);
                                  if (doubleWeight != null && doubleWeight > 0) {
                                    ref.read(settingsProvider.notifier).setUserWeight(doubleWeight);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. Firebase Integrations Section
              _buildSectionTitle('Estado de Integraciones'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: FirebaseService.isInitialized
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.orange.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              FirebaseService.isInitialized ? Icons.cloud_done : Icons.cloud_off,
                              color: FirebaseService.isInitialized ? Colors.green : Colors.orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Servicio de Firebase',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  FirebaseService.isInitialized 
                                      ? 'Conectado. Base de datos e inicio de sesión activos.' 
                                      : 'Modo Offline. ${FirebaseService.errorMessage != null ? '\nDetalle: ${FirebaseService.errorMessage}' : 'Recompila para activar credenciales.'}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: FirebaseService.isInitialized ? Colors.green[800] : Colors.orange[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              FirebaseService.isInitialized ? 'ONLINE' : 'OFFLINE',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. API Live Testing Section
              _buildSectionTitle('Prueba de APIs en Tiempo Real'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Presiona el botón para probar de forma simultánea las llamadas HTTP a las APIs externas usando tu ubicación.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            settings.useSimulation ? Icons.sim_card_outlined : Icons.gps_fixed,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            settings.useSimulation 
                                ? 'Ubicación simulada: Quito, EC (-0.2186, -78.5085)'
                                : 'Obteniendo GPS real del dispositivo...',
                            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _testingAPIs ? null : _runAPIsTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: _testingAPIs
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.network_check),
                        label: Text(
                          _testingAPIs ? 'Llamando APIs...' : 'PROBAR INTEGRACIONES',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                      // API Error message if any
                      if (_apiError != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Error: $_apiError',
                            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],

                      // API Results Display
                      if (_testLat != null && _testLng != null && !_testingAPIs) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Coordenadas de Prueba: (${_testLat!.toStringAsFixed(4)}, ${_testLng!.toStringAsFixed(4)})',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        
                        // 1. Geocoding Address Card
                        _buildApiResultItem(
                          title: 'Conversión de Coordenadas (OpenStreetMap)',
                          value: _addressResult ?? 'Cargando...',
                          icon: Icons.map_outlined,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 10),

                        // 2. Weather Card
                        _buildApiResultItem(
                          title: 'Clima Actual (Open-Meteo)',
                          value: _weatherResult != null
                              ? '${_weatherResult!.temperature.toStringAsFixed(1)}°C – ${_weatherResult!.description}\n(Humedad: ${_weatherResult!.humidity}%, Viento: ${_weatherResult!.windSpeed} km/h)'
                              : 'Cargando...',
                          icon: _weatherResult != null ? _getWeatherIcon(_weatherResult!.weatherCode) : Icons.cloud_outlined,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 10),

                        // 3. Elevation Card
                        _buildApiResultItem(
                          title: 'API de Elevación (Open-Meteo)',
                          value: _elevationResult != null
                              ? '${settings.useMetricUnits ? _elevationResult!.toStringAsFixed(1) : (_elevationResult! * 3.28084).toStringAsFixed(1)} ${settings.useMetricUnits ? 'metros' : 'pies'} msnm'
                              : 'Cargando...',
                          icon: Icons.filter_hdr_outlined,
                          color: Colors.teal,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              
              // 5. App details / ESFOT
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.fitness_center, color: AppTheme.primaryColor, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'FitTrack Pro v1.0.0',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Escuela de Formación de Tecnólogos – EPN',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                    Text(
                      'Proyecto de Aplicaciones Móviles © 2026',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryColor,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildApiResultItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
