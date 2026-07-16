import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:proyecto_gr4/core/errors/api_exception.dart';

typedef TokenReader = Future<String?> Function();

class ApiClient {
  final http.Client client;
  final TokenReader tokenReader;
  final Duration timeout;

  ApiClient({
    required this.client,
    required this.tokenReader,
    this.timeout = const Duration(seconds: 15),
  });

  Future<dynamic> getJson(
    String url, {
    bool authenticated = true,
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      method: 'GET',
      url: url,
      authenticated: authenticated,
      headers: headers,
    );
  }

  Future<dynamic> postJson(
    String url, {
    Object? body,
    bool authenticated = true,
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      method: 'POST',
      url: url,
      body: body,
      authenticated: authenticated,
      headers: headers,
    );
  }

  Future<dynamic> patchJson(
    String url, {
    Object? body,
    bool authenticated = true,
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      method: 'PATCH',
      url: url,
      body: body,
      authenticated: authenticated,
      headers: headers,
    );
  }

  Future<dynamic> deleteJson(
    String url, {
    Object? body,
    bool authenticated = true,
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      method: 'DELETE',
      url: url,
      body: body,
      authenticated: authenticated,
      headers: headers,
    );
  }

  Future<dynamic> _sendRequest({
    required String method,
    required String url,
    Object? body,
    required bool authenticated,
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (headers != null) {
      mergedHeaders.addAll(headers);
    }

    if (authenticated) {
      final token = await tokenReader();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'No existe una sesión válida.',
          statusCode: 401,
        );
      }
      mergedHeaders['Authorization'] = 'Bearer $token';
    }

    try {
      final uri = Uri.parse(url);
      http.Response response;

      final encodedBody = body != null ? jsonEncode(body) : null;

      switch (method) {
        case 'GET':
          response = await client.get(uri, headers: mergedHeaders).timeout(timeout);
          break;
        case 'POST':
          response = await client.post(uri, headers: mergedHeaders, body: encodedBody).timeout(timeout);
          break;
        case 'PATCH':
          response = await client.patch(uri, headers: mergedHeaders, body: encodedBody).timeout(timeout);
          break;
        case 'DELETE':
          response = await client.delete(uri, headers: mergedHeaders, body: encodedBody).timeout(timeout);
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }

      return _handleResponse(response);
    } on TimeoutException {
      throw const ApiException(message: 'Tiempo de espera agotado.');
    } on SocketException {
      throw const ApiException(message: 'No se pudo conectar con el servidor.');
    } on http.ClientException {
      throw const ApiException(message: 'Error de conexión con el servidor.');
    } on FormatException {
      throw const ApiException(message: 'El servidor devolvió una respuesta inválida.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error inesperado: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    // Attempt to decode body if possible
    dynamic decodedBody;
    try {
      if (response.body.isNotEmpty) {
        decodedBody = jsonDecode(response.body);
      }
    } catch (_) {
      // Ignored for raw bodies
    }

    if (statusCode >= 200 && statusCode <= 299) {
      if (statusCode == 204) {
        return null; // Or empty map, returning null is standard for 204 No Content
      }
      if (response.body.isEmpty) {
        return null;
      }
      return decodedBody;
    }

    // Error handling
    String errorMessage = _getDefaultErrorMessage(statusCode);
    
    if (decodedBody != null && decodedBody is Map<String, dynamic>) {
      if (decodedBody.containsKey('message')) {
        errorMessage = decodedBody['message'].toString();
      } else if (decodedBody.containsKey('msg')) {
        errorMessage = decodedBody['msg'].toString();
      } else if (decodedBody.containsKey('error')) {
        errorMessage = decodedBody['error'].toString();
      }
    } else if (response.body.isNotEmpty) {
      // Body might be plain text
      // We don't overwrite standard errors with full HTML pages, but if it's short we could.
      // The requirement says: "4. Texto del body"
      errorMessage = response.body;
    }

    throw ApiException(
      message: errorMessage,
      statusCode: statusCode,
      responseBody: decodedBody ?? response.body,
    );
  }

  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Solicitud inválida.';
      case 401:
        return 'Tu sesión expiró o no es válida.';
      case 403:
        return 'No tienes permiso para realizar esta acción.';
      case 404:
        return 'El recurso solicitado no existe.';
      case 409:
        return 'La información enviada genera un conflicto.';
      case 500:
        return 'Ocurrió un error interno en el servidor.';
      case 502:
        return 'Un servicio externo no respondió correctamente.';
      default:
        return 'Ocurrió un error inesperado ($statusCode).';
    }
  }
}
