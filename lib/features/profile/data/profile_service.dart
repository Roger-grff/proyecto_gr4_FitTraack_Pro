import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/core/constants/api_constants.dart';
import 'package:proyecto_gr4/core/errors/api_exception.dart';
import 'package:proyecto_gr4/core/providers/api_client_provider.dart';
import 'package:proyecto_gr4/core/services/api_client.dart';
import 'package:proyecto_gr4/features/auth/domain/app_user.dart';
import 'package:proyecto_gr4/features/profile/data/models/update_profile_request.dart';

class ProfileService {
  final ApiClient apiClient;

  ProfileService({required this.apiClient});

  Future<AppUser> getProfile() async {
    final response = await apiClient.getJson(ApiConstants.usersMe);
    if (response is! Map<String, dynamic> || response['user'] is! Map<String, dynamic>) {
      throw const ApiException(message: 'Respuesta inválida del servidor.');
    }
    return AppUser.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<AppUser> updateProfile(UpdateProfileRequest request) async {
    final body = request.toJson();
    if (body.isEmpty) {
      throw const ApiException(message: 'No hay campos para actualizar.');
    }

    final response = await apiClient.patchJson(
      ApiConstants.usersMe,
      body: body,
    );

    if (response is! Map<String, dynamic> || response['user'] is! Map<String, dynamic>) {
      throw const ApiException(message: 'Respuesta inválida del servidor.');
    }
    return AppUser.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<AppUser> uploadProfilePhoto(String filePath) async {
    final response = await apiClient.postMultipart(
      ApiConstants.usersMePhoto,
      filePath: filePath,
      fileField: 'photo',
    );

    if (response is! Map<String, dynamic> || response['user'] is! Map<String, dynamic>) {
      throw const ApiException(message: 'Respuesta inválida del servidor al subir foto.');
    }
    return AppUser.fromJson(response['user'] as Map<String, dynamic>);
  }
}

final profileServiceProvider = Provider<ProfileService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileService(apiClient: apiClient);
});
