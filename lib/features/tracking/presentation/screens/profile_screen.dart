import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_gr4/core/theme/app_theme.dart';
import 'package:proyecto_gr4/features/auth/presentation/controllers/auth_provider.dart';
import 'package:proyecto_gr4/features/auth/presentation/screens/login_screen.dart';
import 'package:proyecto_gr4/features/profile/presentation/controllers/profile_controller.dart';
import 'package:proyecto_gr4/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:proyecto_gr4/features/stats/presentation/controllers/stats_controller.dart';
import 'package:proyecto_gr4/features/tracking/presentation/controllers/activities_controller.dart';
import 'package:proyecto_gr4/features/tracking/presentation/screens/activity_detail_screen.dart';
import 'package:proyecto_gr4/features/tracking/presentation/widgets/backend_activity_card.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  String _formatPace(double pace) {
    return '${pace ~/ 60}:${pace.round().remainder(60).toString().padLeft(2, '0')} /km';
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final length = await image.length();
    if (length > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La imagen supera los 5 MB permitidos.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Actualizar foto'),
        content: const Text('¿Deseas usar esta imagen como foto de perfil?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Subir')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      await ref.read(profileProvider.notifier).uploadPhoto(image.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotografía actualizada correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(statsProvider);
    final activitiesAsync = ref.watch(activitiesProvider);

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
          await Future.wait([
            ref.read(profileProvider.notifier).refreshProfile(),
            ref.read(statsProvider.notifier).refreshStats(),
            ref.read(activitiesProvider.notifier).refreshActivities(),
          ]);
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              // PERFIL SECCIÓN
              profileAsync.when(
                loading: () => const Center(
                  child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      Text('Error cargando perfil: $error', textAlign: TextAlign.center),
                      TextButton(
                        onPressed: () => ref.read(profileProvider.notifier).refreshProfile(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
                data: (user) {
                  final memberSince = DateFormat('MMMM yyyy', 'es').format(user.createdAt);
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadPhoto,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            _ProfileAvatar(
                              photoUrl: user.photoUrl,
                              name: user.name.isNotEmpty ? user.name : 'C',
                            ),
                            if (_isUploadingPhoto)
                              const Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(user.name.isNotEmpty ? user.name : 'Corredor FitTrack',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        'Corredor desde ${toBeginningOfSentenceCase(memberSince)}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(.6)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditProfileScreen(currentUser: user)),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar perfil'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // STATS SECCIÓN
              statsAsync.when(
                loading: () => const Center(
                  child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const Text('Error cargando estadísticas.'),
                      TextButton(
                        onPressed: () => ref.read(statsProvider.notifier).refreshStats(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
                data: (stats) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _SummaryMetric(value: '${stats.totalActivities}', label: 'SALIDAS'),
                            _divider(),
                            _SummaryMetric(value: stats.totalDistance.toStringAsFixed(1), label: 'KM TOTALES'),
                            _divider(),
                            _SummaryMetric(value: stats.bestPace != null ? _formatPace(stats.bestPace!) : '--', label: 'MEJOR RITMO'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text('Tu progreso', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _ProgressCard(icon: Icons.monitor_weight_outlined, title: 'IMC', value: stats.imc != null ? stats.imc!.toStringAsFixed(1) : '-', color: const Color(0xFFFF9F1C), subtitle: stats.imc == null ? 'Completa peso y altura' : null)),
                          const SizedBox(width: 12),
                          Expanded(child: _ProgressCard(icon: Icons.local_fire_department_outlined, title: 'Balance Calorías', value: '${stats.balanceCalorico.balance > 0 ? '+' : ''}${stats.balanceCalorico.balance.toInt()} kcal', color: AppTheme.primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.health_and_safety_outlined, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Objetivo Semanal OMS', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${stats.oms.minutosUltimaSemana} min', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text('${stats.oms.recomendadoMinutosSemana} min', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: (stats.oms.porcentajeCumplido / 100).clamp(0.0, 1.0),
                                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                                color: stats.oms.cumpleRecomendacionOMS ? Colors.green : AppTheme.primaryColor,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                stats.oms.cumpleRecomendacionOMS ? '¡Felicitaciones! Cumples la recomendación.' : 'Sigue esforzándote para alcanzar la meta.',
                                style: theme.textTheme.bodySmall,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              
              // HISTORIAL SECCIÓN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Historial de carreras', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              activitiesAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
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
                        onTap: () async {
                          final deleted = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => ActivityDetailScreen(activityId: activity.id),
                            ),
                          );

                          if (!context.mounted) return;
                          if (deleted == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Actividad eliminada correctamente.')),
                            );
                          }
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
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 48,
      backgroundColor: AppTheme.primaryColor.withOpacity(.15),
      backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
      onBackgroundImageError: photoUrl?.isNotEmpty == true ? (exception, stackTrace) {} : null,
      child: photoUrl?.isNotEmpty == true
          ? null
          : Text(name.isNotEmpty ? name[0].toUpperCase() : 'C', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(.8), fontSize: 9, fontWeight: FontWeight.bold))]));
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.icon, required this.title, required this.value, required this.color, this.subtitle});
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 12), Text(title, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 3), Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.error))]])));
}
