import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_provider.dart';
import 'package:proyecto_gr4/features/auth/presentation/screens/login_screen.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/activities_controller.dart';
import 'package:proyecto_gr4/features/tracking/presentation/screens/activity_detail_screen.dart';
import 'package:proyecto_gr4/features/tracking/presentation/widgets/backend_activity_card.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours} h ${minutes} min' : '$minutes min';
  }

  String _averagePace(List<BackendActivity> activities) {
    final distance = activities.fold<double>(0, (sum, item) => sum + item.distanceKm);
    final seconds = activities.fold<int>(0, (sum, item) => sum + item.durationSeconds);
    if (distance <= 0) return '--:-- /km';
    final pace = seconds / distance;
    return '${pace ~/ 60}:${pace.round().remainder(60).toString().padLeft(2, '0')} /km';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final activitiesAsync = ref.watch(activitiesProvider);
    
    // Stats calc
    final activities = activitiesAsync.asData?.value ?? [];
    final totalKm = activities.fold<double>(0, (sum, item) => sum + item.distanceKm);
    final totalDuration = activities.fold<Duration>(Duration.zero, (sum, item) => sum + Duration(seconds: item.durationSeconds));
    final bestDistance = activities.isEmpty
        ? 0.0
        : activities.map((item) => item.distanceKm).reduce((a, b) => a > b ? a : b);
    final memberSince = user == null ? null : DateFormat('MMMM yyyy', 'es').format(user.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(activitiesProvider.notifier).refreshActivities();
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Center(
                child: Column(
                  children: [
                    _ProfileAvatar(photoUrl: user?.photoUrl, name: user?.name ?? 'Corredor'),
                    const SizedBox(height: 12),
                    Text(user?.name.isNotEmpty == true ? user!.name : 'Corredor FitTrack',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      memberSince == null ? 'Atleta FitTrack' : 'Corredor desde ${toBeginningOfSentenceCase(memberSince)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _SummaryMetric(value: '${activities.length}', label: 'SALIDAS'),
                    _divider(),
                    _SummaryMetric(value: totalKm.toStringAsFixed(1), label: 'KM TOTALES'),
                    _divider(),
                    _SummaryMetric(value: _formatDuration(totalDuration), label: 'TIEMPO'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Tu progreso', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _ProgressCard(icon: Icons.emoji_events_outlined, title: 'Mayor distancia', value: '${bestDistance.toStringAsFixed(2)} km', color: const Color(0xFFFF9F1C))),
                  const SizedBox(width: 12),
                  Expanded(child: _ProgressCard(icon: Icons.local_fire_department_outlined, title: 'Ritmo promedio', value: _averagePace(activities), color: AppTheme.primaryColor)),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Historial de carreras', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  if (activities.isNotEmpty)
                    Text('${activities.length} registradas', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              
              // Historial con AsyncValue
              activitiesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando historial...'),
                      ],
                    ),
                  ),
                ),
                error: (error, stack) {
                  final msg = ref.read(activitiesProvider.notifier).getErrorMessage(error);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 16),
                          Text(msg, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref.read(activitiesProvider.notifier).refreshActivities(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                data: (data) {
                  if (data.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          children: [
                            Icon(Icons.directions_run_outlined, size: 48, color: theme.colorScheme.onSurface.withOpacity(.35)),
                            const SizedBox(height: 10),
                            const Text('Aún no hay carreras registradas', style: TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('Finaliza tu primera actividad y aquí verás tu progreso.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: data.map((activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BackendActivityCard(
                        activity: activity,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ActivityDetailScreen(activityId: activity.id),
                            ),
                          );
                        },
                      ),
                    )).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  final shouldSignOut = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content: const Text('¿Seguro que deseas cerrar tu sesión?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    ),
                  );
                  if (shouldSignOut != true || !context.mounted) return;
                  await ref.read(authProvider.notifier).signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error.withOpacity(.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 34, color: Colors.white.withOpacity(.35));
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.photoUrl, required this.name});
  final String? photoUrl;
  final String name;
  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 48,
        backgroundColor: AppTheme.primaryColor.withOpacity(.15),
        backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
        child: photoUrl?.isNotEmpty == true
            ? null
            : Text(name.isNotEmpty ? name[0].toUpperCase() : 'C', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
      );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(.8), fontSize: 9, fontWeight: FontWeight.bold))]));
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.icon, required this.title, required this.value, required this.color});
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 12), Text(title, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 3), Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))])));
}
