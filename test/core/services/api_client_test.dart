import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:proyecto_gr4/core/services/api_client.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';


void main() {
  group('ApiClient Tests', () {
    const testUrl = 'https://api.example.com/data';
    const testToken = 'token-de-prueba';

    Future<String?> mockTokenReader() async => testToken;
    Future<String?> nullTokenReader() async => null;
    Future<String?> emptyTokenReader() async => '';

    ApiClient createClient(http.Client client, {TokenReader? tokenReader}) {
      return ApiClient(
        client: client,
        tokenReader: tokenReader ?? mockTokenReader,
      );
    }

    test('1. GET privado agrega Authorization Bearer', () async {
      final client = createClient(MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer $testToken');
        return http.Response('{}', 200);
      }));
      await client.getJson(testUrl);
    });

    test('2. POST privado agrega Authorization Bearer', () async {
      final client = createClient(MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer $testToken');
        return http.Response('{}', 200);
      }));
      await client.postJson(testUrl, body: {'key': 'val'});
    });

    test('3. PATCH privado agrega Authorization Bearer', () async {
      final client = createClient(MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer $testToken');
        return http.Response('{}', 200);
      }));
      await client.patchJson(testUrl, body: {'key': 'val'});
    });

    test('4. DELETE privado agrega Authorization Bearer', () async {
      final client = createClient(MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer $testToken');
        return http.Response('{}', 200);
      }));
      await client.deleteJson(testUrl);
    });

    test('5. authenticated false no envia Authorization', () async {
      final client = createClient(MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response('{}', 200);
      }));
      await client.getJson(testUrl, authenticated: false);
    });

    test('6. Token null lanza ApiException', () async {
      final client = createClient(MockClient((request) async => http.Response('{}', 200)), tokenReader: nullTokenReader);
      expect(() => client.getJson(testUrl), throwsA(isA<ApiException>()));
    });

    test('7. Token vacio lanza ApiException', () async {
      final client = createClient(MockClient((request) async => http.Response('{}', 200)), tokenReader: emptyTokenReader);
      expect(() => client.getJson(testUrl), throwsA(isA<ApiException>()));
    });

    test('8. Respuesta 200 con Map devuelve el JSON', () async {
      final client = createClient(MockClient((request) async => http.Response('{"id": 1}', 200)));
      final res = await client.getJson(testUrl);
      expect(res, isA<Map<String, dynamic>>());
      expect(res['id'], 1);
    });

    test('9. Respuesta 200 con List devuelve la lista', () async {
      final client = createClient(MockClient((request) async => http.Response('[{"id": 1}]', 200)));
      final res = await client.getJson(testUrl);
      expect(res, isA<List<dynamic>>());
      expect(res[0]['id'], 1);
    });

    test('10. Respuesta 201 devuelve el JSON', () async {
      final client = createClient(MockClient((request) async => http.Response('{"created": true}', 201)));
      final res = await client.postJson(testUrl);
      expect(res['created'], true);
    });

    test('11. Respuesta 204 no produce FormatException', () async {
      final client = createClient(MockClient((request) async => http.Response('', 204)));
      final res = await client.deleteJson(testUrl);
      expect(res, isNull);
    });

    test('12. POST convierte correctamente el body a JSON', () async {
      final client = createClient(MockClient((request) async {
        expect(request.body, '{"name":"test"}');
        return http.Response('{}', 200);
      }));
      await client.postJson(testUrl, body: {'name': 'test'});
    });

    test('13. PATCH convierte correctamente el body a JSON', () async {
      final client = createClient(MockClient((request) async {
        expect(request.body, '{"name":"patch"}');
        return http.Response('{}', 200);
      }));
      await client.patchJson(testUrl, body: {'name': 'patch'});
    });

    test('14. DELETE funciona sin body', () async {
      final client = createClient(MockClient((request) async {
        expect(request.body, isEmpty);
        return http.Response('{}', 204);
      }));
      await client.deleteJson(testUrl);
    });

    test('15. Error 400 obtiene el campo message', () async {
      final client = createClient(MockClient((request) async => http.Response('{"message": "Error from server"}', 400)));
      try {
        await client.getJson(testUrl);
      } on ApiException catch (e) {
        expect(e.message, 'Error from server');
        expect(e.statusCode, 400);
      }
    });

    test('16. Error 400 obtiene el campo msg cuando no existe message', () async {
      final client = createClient(MockClient((request) async => http.Response('{"msg": "Msg error"}', 400)));
      try {
        await client.getJson(testUrl);
      } on ApiException catch (e) {
        expect(e.message, 'Msg error');
      }
    });

    test('17. Error 401 conserva statusCode 401', () async {
      final client = createClient(MockClient((request) async => http.Response('{"error": "Unauthorized"}', 401)));
      try {
        await client.getJson(testUrl);
      } on ApiException catch (e) {
        expect(e.statusCode, 401);
        expect(e.message, 'Unauthorized');
      }
    });

    test('18. Error 403 conserva statusCode 403', () async {
      final client = createClient(MockClient((request) async => http.Response('', 403)));
      try {
        await client.getJson(testUrl);
      } on ApiException catch (e) {
        expect(e.statusCode, 403);
        expect(e.message, 'No tienes permiso para realizar esta acción.');
      }
    });

    test('19. Error 404 conserva statusCode 404', () async {
      final client = createClient(MockClient((request) async => http.Response('', 404)));
      try {
        await client.getJson(testUrl);
      } on ApiException catch (e) {
        expect(e.statusCode, 404);
        expect(e.message, 'El recurso solicitado no existe.');
      }
    });

    test('20. Error 409 conserva statusCode 409', () async {
      final client = createClient(MockClient((request) async => http.Response('', 409)));
      try {
        await client.getJson(testUrl);
      } on ApiException catch (e) {
        expect(e.statusCode, 409);
        expect(e.message, 'La información enviada genera un conflicto.');
      }
    });

    test('21. Error 500 conserva statusCode 500', () async {
      final client = createClient(MockClient((request) async => http.Response('', 500)));
      try {
        await client.getJson(testUrl);
      } on ApiException catch (e) {
        expect(e.statusCode, 500);
        expect(e.message, 'Ocurrió un error interno en el servidor.');
      }
    });

    test('22. Respuesta de error no JSON utiliza un mensaje alternativo', () async {
      final client = createClient(MockClient((request) async => http.Response('Html error page', 502)));
      try {
        await client.getJson(testUrl);
      } on ApiException catch (e) {
        expect(e.statusCode, 502);
        expect(e.message, 'Html error page'); // Como dice el requisito de body como texto
      }
    });

    test('23. Respuesta exitosa vacia no genera error', () async {
      final client = createClient(MockClient((request) async => http.Response('', 200)));
      final res = await client.getJson(testUrl);
      expect(res, isNull);
    });

    test('24. Timeout se convierte en ApiException', () async {
      // MockClient no tira TimeoutException fácil, así que mockeamos un cliente q tira la excepción
      final timeoutClient = _ThrowingClient(TimeoutException('Timeout'));
      final client = createClient(timeoutClient);
      
      try {
        await client.getJson(testUrl);
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.message, 'Tiempo de espera agotado.');
      }
    });

    test('25. Los headers personalizados se combinan con los predeterminados', () async {
      final client = createClient(MockClient((request) async {
        expect(request.headers['Custom-Header'], 'Value');
        expect(request.headers['Accept'], 'application/json');
        return http.Response('{}', 200);
      }));
      await client.getJson(testUrl, headers: {'Custom-Header': 'Value'});
    });
  });
}

class _ThrowingClient extends http.BaseClient {
  final Exception exception;
  _ThrowingClient(this.exception);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw exception;
  }
}
