import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_provider.dart';
import 'package:proyecto_gr4/features/auth/presentation/screens/login_screen.dart';
import 'package:proyecto_gr4/features/tracking/domain/activity_session.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/tracking_controller.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours} h ${minutes} min' : '$minutes min';
  }

  String _formatPace(ActivitySession session) {
    final km = session.stats.distanceKm;
    if (km <= 0) return '--:-- /km';
    final seconds = session.stats.duration.inSeconds / km;
    final minutes = seconds ~/ 60;
    final remainder = seconds.round().remainder(60).toString().padLeft(2, '0');
    return '$minutes:$remainder /km';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final activities = ref.watch(completedActivitiesProvider);
    final totalKm = activities.fold<double>(0, (sum, item) => sum + item.stats.distanceKm);
    final totalDuration = activities.fold<Duration>(Duration.zero, (sum, item) => sum + item.stats.duration);
    final bestDistance = activities.isEmpty
        ? 0.0
        : activities.map((item) => item.stats.distanceKm).reduce((a, b) => a > b ? a : b);
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
      body: SafeArea(
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
                Text('${activities.length} registradas', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty) _EmptyHistory()
            else ...activities.map((activity) => _ActivityHistoryCard(activity: activity, pace: _formatPace(activity))),
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
    );
  }

  Widget _divider() => Container(width: 1, height: 34, color: Colors.white.withOpacity(.35));

  String _averagePace(List<ActivitySession> activities) {
    final distance = activities.fold<double>(0, (sum, item) => sum + item.stats.distanceKm);
    final seconds = activities.fold<int>(0, (sum, item) => sum + item.stats.duration.inSeconds);
    if (distance <= 0) return '--:-- /km';
    final pace = seconds / distance;
    return '${pace ~/ 60}:${pace.round().remainder(60).toString().padLeft(2, '0')} /km';
  }
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

class _ActivityHistoryCard extends StatelessWidget {
  const _ActivityHistoryCard({required this.activity, required this.pace});
  final ActivitySession activity;
  final String pace;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(backgroundColor: AppTheme.primaryColor.withOpacity(.14), child: const Icon(Icons.directions_run, color: AppTheme.primaryColor)),
        title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(DateFormat("EEE, d 'de' MMMM · HH:mm", 'es').format(activity.startTime), style: theme.textTheme.bodySmall),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('${activity.stats.distanceKm.toStringAsFixed(2)} km', style: const TextStyle(fontWeight: FontWeight.w900)), Text(pace, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor))]),
      )),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(26), child: Column(children: [Icon(Icons.directions_run_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(.35)), const SizedBox(height: 10), const Text('Aún no hay carreras registradas', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('Finaliza tu primera actividad y aquí verás tu progreso.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)])));
}
