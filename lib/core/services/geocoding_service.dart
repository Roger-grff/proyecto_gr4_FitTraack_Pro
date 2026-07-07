import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  /// Convert coordinates (lat, lng) to a readable address in Spanish using Nominatim
  Future<String> reverseGeocode(double lat, double lng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FitTrackPro/1.0 (contact@fittrackpro.com)',
          'Accept-Language': 'es',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> address = data['address'] ?? {};
        
        final String? road = address['road'];
        final String? houseNumber = address['house_number'];
        final String? neighbourhood = address['neighbourhood'] ?? address['suburb'] ?? address['village'];
        final String? city = address['city'] ?? address['town'] ?? address['county'];
        final String? country = address['country'];

        // Build custom friendly address
        final List<String> parts = [];
        
        if (road != null) {
          if (houseNumber != null) {
            parts.add('$road $houseNumber');
          } else {
            parts.add(road);
          }
        }
        
        if (neighbourhood != null) {
          parts.add(neighbourhood);
        }
        
        if (city != null) {
          parts.add(city);
        }
        
        if (country != null) {
          parts.add(country);
        }

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
        
        // Fallback to display name
        return data['display_name'] ?? 'Dirección desconocida';
      } else {
        throw Exception('Error en respuesta de geocodificación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fallo al convertir coordenadas a dirección: $e');
    }
  }
}
