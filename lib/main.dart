import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/features/tracking/presentation/screens/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:proyecto_gr4/core/services/firebase_service.dart';
import 'package:proyecto_gr4/core/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe Firebase Initialization (tolerates missing credentials/offline mode)
  await FirebaseService.initialize();
  
  // Initialize date formatting locale for Spanish summaries
  await initializeDateFormatting('es', null);
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      title: 'GPS Tracker Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode, // Dynamically follow settings themeMode
      home: const HomeScreen(),
    );
  }
}
