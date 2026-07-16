import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_gr4/features/profile/data/models/update_profile_request.dart';
import 'package:proyecto_gr4/features/profile/data/profile_service.dart';
import 'package:proyecto_gr4/core/services/api_client.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';
import 'package:http/http.dart' as http;

class MockApiClient implements ApiClient {
  @override
  final http.Client client = http.Client();
  @override
  final TokenReader tokenReader = () async => "token";
  @override
  final Duration timeout = const Duration(seconds: 15);

  Map<String, dynamic>? mockGetResponse;
  Map<String, dynamic>? mockPatchResponse;
  Map<String, dynamic>? mockMultipartResponse;
  Exception? mockException;

  @override
  Future deleteJson(String url, {Object? body, bool authenticated = true, Map<String, String>? headers}) async => null;

  @override
  Future getJson(String url, {bool authenticated = true, Map<String, String>? headers}) async {
    if (mockException != null) throw mockException!;
    return mockGetResponse;
  }

  @override
  Future patchJson(String url, {Object? body, bool authenticated = true, Map<String, String>? headers}) async {
    if (mockException != null) throw mockException!;
    return mockPatchResponse;
  }

  @override
  Future postJson(String url, {Object? body, bool authenticated = true, Map<String, String>? headers}) async => null;

  @override
  Future postMultipart(String url, {required String filePath, required String fileField, bool authenticated = true, Map<String, String>? fields}) async {
    if (mockException != null) throw mockException!;
    return mockMultipartResponse;
  }
}

void main() {
  late MockApiClient mockApiClient;
  late ProfileService service;

  setUp(() {
    mockApiClient = MockApiClient();
    service = ProfileService(apiClient: mockApiClient);
  });

  group('ProfileService Tests', () {
    final validUserJson = {
      "user": {
        "_id": "123",
        "email": "test@test.com",
        "name": "Test",
        "createdAt": "2026-07-10T12:00:00Z"
      }
    };

    test('1. GET profile correcto', () async {
      mockApiClient.mockGetResponse = validUserJson;
      final user = await service.getProfile();
      expect(user.id, "123");
      expect(user.name, "Test");
    });

    test('2. PATCH profile correcto', () async {
      mockApiClient.mockPatchResponse = validUserJson;
      final req = UpdateProfileRequest(name: "Test");
      final user = await service.updateProfile(req);
      expect(user.name, "Test");
    });

    test('3. PATCH profile rechaza vacio', () async {
      expect(() => UpdateProfileRequest(), throwsArgumentError);
    });

    test('4. POST multipart correcto', () async {
      mockApiClient.mockMultipartResponse = validUserJson;
      final user = await service.uploadProfilePhoto('test.jpg');
      expect(user.id, "123");
    });

    test('5. Propaga ApiException', () async {
      mockApiClient.mockException = const ApiException(message: "Error 500", statusCode: 500);
      expect(() => service.getProfile(), throwsA(isA<ApiException>()));
    });
  });
}
