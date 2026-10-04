import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/workout_progress_bar.dart';

/// A past workout session's full breakdown: the same time-vs-pace bar shown
/// right after finishing it, plus every exercise's sets with whatever
/// weight/reps were logged — reached by tapping a row in Stats' recent
/// sessions list.
class SessionDetailScreen extends StatelessWidget {
  final WorkoutAppState app;
  const SessionDetailScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final index = app.selectedSessionIndex;
    if (index == null || index >= app.data.history.length) return const SizedBox.shrink();
    final h = app.data.history[index];
    final diff = h.targetSeconds - h.durationSeconds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.text),
                onPressed: app.closeSessionDetail,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.templateName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                    Text(h.date, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Text('+${h.xpEarned} XP', style: const TextStyle(fontSize: 14, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${formatDuration(h.durationSeconds)} of a ${formatDuration(h.targetSeconds)} target '
            '${diff >= 0 ? '(${formatDuration(diff)} to spare)' : '(${formatDuration(-diff)} over)'}',
            style: TextStyle(fontSize: 13, color: h.onPace ? AppColors.good : AppColors.danger),
          ),
          const SizedBox(height: 16),
          if (h.completedExercises.isEmpty)
            const PanelBox(
              child: Text(
                "This session was logged before per-exercise breakdowns were saved, so there's nothing more to show here.",
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            )
          else ...[
            PanelBox(
              child: WorkoutProgressBar(
                targetSeconds: h.targetSeconds,
                elapsedSeconds: h.durationSeconds,
                fillColor: h.onPace ? AppColors.good : AppColors.danger,
                completedExercises: h.completedExercises,
              ),
            ),
            const SizedBox(height: 16),
            for (final ce in h.completedExercises) ...[
              PanelBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(ce.exerciseName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text)),
                        ),
                        Text(formatDuration(ce.durationSeconds), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final set in ce.sets)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Set ${set.setNumber}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                            Text(_setStats(set), style: const TextStyle(fontSize: 13, color: AppColors.text)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  String _setStats(SetEntry set) {
    if (set.weight != null) return '${formatNumber(set.weight!)} × ${set.reps ?? '?'}';
    if (set.reps != null) return '${set.reps} reps';
    return '—';
  }
}
