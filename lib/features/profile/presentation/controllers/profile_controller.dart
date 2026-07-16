import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/features/auth/domain/app_user.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_provider.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_state.dart';
import 'package:proyecto_gr4/features/profile/data/models/update_profile_request.dart';
import 'package:proyecto_gr4/features/profile/data/profile_service.dart';

class ProfileNotifier extends AsyncNotifier<AppUser> {
  ProfileService get _service => ref.read(profileServiceProvider);

  @override
  Future<AppUser> build() async {
    // Escuchar el authProvider para invalidarse si hay logout
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        ref.invalidateSelf();
      }
    });

    return _service.getProfile();
  }

  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    try {
      final user = await _service.getProfile();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile(UpdateProfileRequest request) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      final updatedUser = await _service.updateProfile(request);
      state = AsyncValue.data(updatedUser);
      ref.read(authProvider.notifier).updateUser(updatedUser);
    } catch (e, stack) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> uploadPhoto(String filePath) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      final updatedUser = await _service.uploadProfilePhoto(filePath);
      state = AsyncValue.data(updatedUser);
      ref.read(authProvider.notifier).updateUser(updatedUser);
    } catch (e, stack) {
      state = previousState;
      rethrow;
    }
  }
}

final profileProvider = AsyncNotifierProvider.autoDispose<ProfileNotifier, AppUser>(() {
  return ProfileNotifier();
});
