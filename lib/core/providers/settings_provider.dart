import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proyecto_gr4/features/tracking/data/tracking_repository.dart';

class SettingsState {
  final ThemeMode themeMode;
  final bool useMetricUnits;
  final bool enableWeather;
  final bool enableElevation;
  final double userWeight;
  final bool useSimulation;

  SettingsState({
    required this.themeMode,
    required this.useMetricUnits,
    required this.enableWeather,
    required this.enableElevation,
    required this.userWeight,
    required this.useSimulation,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? useMetricUnits,
    bool? enableWeather,
    bool? enableElevation,
    double? userWeight,
    bool? useSimulation,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      useMetricUnits: useMetricUnits ?? this.useMetricUnits,
      enableWeather: enableWeather ?? this.enableWeather,
      enableElevation: enableElevation ?? this.enableElevation,
      userWeight: userWeight ?? this.userWeight,
      useSimulation: useSimulation ?? this.useSimulation,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const String _keyThemeMode = 'settings_theme_mode';
  static const String _keyMetricUnits = 'settings_metric_units';
  static const String _keyWeather = 'settings_weather';
  static const String _keyElevation = 'settings_elevation';
  static const String _keyWeight = 'settings_weight';
  static const String _keySimulation = 'settings_simulation';

  late SharedPreferences _prefs;

  @override
  SettingsState build() {
    _initPrefs();

    return SettingsState(
      themeMode: ThemeMode.system,
      useMetricUnits: true,
      enableWeather: true,
      enableElevation: true,
      userWeight: 70.0,
      useSimulation: false,
    );
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      final themeIndex = _prefs.getInt(_keyThemeMode) ?? 0;
      final themeMode = themeIndex >= 0 && themeIndex < ThemeMode.values.length 
          ? ThemeMode.values[themeIndex] 
          : ThemeMode.system;
          
      final useMetric = _prefs.getBool(_keyMetricUnits) ?? true;
      final enableW = _prefs.getBool(_keyWeather) ?? true;
      final enableE = _prefs.getBool(_keyElevation) ?? true;
      final weight = _prefs.getDouble(_keyWeight) ?? 70.0;
      final simulation = _prefs.getBool(_keySimulation) ?? false;

      // Apply to Location Service
      ref.read(locationServiceProvider).useSimulation = simulation;

      state = SettingsState(
        themeMode: themeMode,
        useMetricUnits: useMetric,
        enableWeather: enableW,
        enableElevation: enableE,
        userWeight: weight,
        useSimulation: simulation,
      );
    } catch (e) {
      debugPrint("Error loading SharedPreferences: $e");
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      await _prefs.setInt(_keyThemeMode, mode.index);
    } catch (e) {
      debugPrint("Error saving theme mode: $e");
    }
  }

  Future<void> toggleUnitSystem(bool useMetric) async {
    state = state.copyWith(useMetricUnits: useMetric);
    try {
      await _prefs.setBool(_keyMetricUnits, useMetric);
    } catch (e) {
      debugPrint("Error saving unit system: $e");
    }
  }

  Future<void> toggleWeather(bool enable) async {
    state = state.copyWith(enableWeather: enable);
    try {
      await _prefs.setBool(_keyWeather, enable);
    } catch (e) {
      debugPrint("Error saving weather setting: $e");
    }
  }

  Future<void> toggleElevation(bool enable) async {
    state = state.copyWith(enableElevation: enable);
    try {
      await _prefs.setBool(_keyElevation, enable);
    } catch (e) {
      debugPrint("Error saving elevation setting: $e");
    }
  }

  Future<void> setUserWeight(double weight) async {
    state = state.copyWith(userWeight: weight);
    try {
      await _prefs.setDouble(_keyWeight, weight);
    } catch (e) {
      debugPrint("Error saving user weight: $e");
    }
  }

  Future<void> toggleSimulation(bool enable) async {
    state = state.copyWith(useSimulation: enable);
    ref.read(locationServiceProvider).useSimulation = enable;
    try {
      await _prefs.setBool(_keySimulation, enable);
    } catch (e) {
      debugPrint("Error saving simulation setting: $e");
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
