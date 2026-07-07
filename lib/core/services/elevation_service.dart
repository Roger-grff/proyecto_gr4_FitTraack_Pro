import 'dart:convert';
import 'package:http/http.dart' as http;

class ElevationService {
  /// Fetch elevation in meters from Open-Meteo Elevation API for coordinates
  Future<double> fetchElevation(double lat, double lng) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/elevation?latitude=$lat&longitude=$lng',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> elevations = data['elevation'] ?? [];
        if (elevations.isNotEmpty) {
          return (elevations.first as num).toDouble();
        } else {
          throw Exception('No se encontraron datos de elevación en la respuesta.');
        }
      } else {
        throw Exception('Error en respuesta de elevación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo al obtener elevación: $e');
    }
  }
}
