import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyecto_gr4/features/tracking/data/models/backend_activity.dart';
import 'package:proyecto_gr4/features/tracking/presentation/utils/activity_type_ui.dart';

class BackendActivityCard extends StatelessWidget {
  final BackendActivity activity;
  final VoidCallback? onTap;

  const BackendActivityCard({super.key, required this.activity, this.onTap});

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = ActivityTypeHelper.getIcon(activity.type);
    final color = ActivityTypeHelper.getColor(activity.type);
    final dateStr = DateFormat("EEE, d 'de' MMM · HH:mm", 'es').format(activity.startedAt);
    final durationStr = _formatDuration(activity.durationSeconds);

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          ActivityTypeHelper.translate(activity.type),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        Text(
                          ' • $dateStr',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniStat(theme, 'Distancia', '${activity.distanceKm.toStringAsFixed(2)} km'),
                        _buildMiniStat(theme, 'Duración', durationStr),
                        if (activity.avgSpeed > 0)
                          _buildMiniStat(theme, 'Vel. Promedio', '${activity.avgSpeed.toStringAsFixed(1)} km/h')
                        else if (activity.avgPace > 0)
                          _buildMiniStat(theme, 'Ritmo', '${activity.avgPace.toStringAsFixed(2)} /km'),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
