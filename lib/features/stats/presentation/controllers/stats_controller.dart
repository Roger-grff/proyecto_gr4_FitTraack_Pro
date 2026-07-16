import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_provider.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_state.dart';
import 'package:proyecto_gr4/features/stats/data/models/user_stats.dart';
import 'package:proyecto_gr4/features/stats/data/stats_service.dart';

class StatsNotifier extends AsyncNotifier<UserStats> {
  StatsService get _service => ref.read(statsServiceProvider);

  @override
  Future<UserStats> build() async {
    // Escuchar el authProvider para invalidarse si hay logout
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        ref.invalidateSelf();
      }
    });

    return _service.getMyStats();
  }

  Future<void> refreshStats() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _service.getMyStats();
      state = AsyncValue.data(stats);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final statsProvider = AsyncNotifierProvider.autoDispose<StatsNotifier, UserStats>(() {
  return StatsNotifier();
});
