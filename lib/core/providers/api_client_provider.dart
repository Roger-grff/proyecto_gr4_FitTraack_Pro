import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto_gr4/core/services/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  const storage = FlutterSecureStorage();
  final client = http.Client();

  ref.onDispose(() {
    client.close();
  });

  return ApiClient(
    client: client,
    tokenReader: () => storage.read(key: 'jwt_token'),
  );
});
