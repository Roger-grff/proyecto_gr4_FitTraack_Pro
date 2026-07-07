import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final String description;
  final int weatherCode;
  final double humidity;
  final double windSpeed;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.weatherCode,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final int code = current['weather_code'] ?? 0;
    
    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      description: _mapWeatherCodeToText(code),
      weatherCode: code,
      humidity: (current['relative_humidity_2m'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
    );
  }

  static String _mapWeatherCodeToText(int code) {
    switch (code) {
      case 0:
        return 'Cielo Despejado';
      case 1:
      case 2:
      case 3:
        return 'Parcialmente Nublado';
      case 45:
      case 48:
        return 'Niebla';
      case 51:
      case 53:
      case 55:
        return 'Llovizna Ligera';
      case 61:
      case 63:
      case 65:
        return 'Lluvia Moderada';
      case 71:
      case 73:
      case 75:
        return 'Nieve';
      case 80:
      case 81:
      case 82:
        return 'Chubascos';
      case 95:
      case 96:
      case 99:
        return 'Tormenta Eléctrica';
      default:
        return 'Clima Variable';
    }
  }
}

class WeatherService {
  /// Fetch weather details from Open-Meteo for coordinates
  Future<WeatherData> fetchWeather(double lat, double lng) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Error en respuesta del clima: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo al obtener clima: $e');
    }
  }
}
