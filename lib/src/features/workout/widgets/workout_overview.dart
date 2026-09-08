import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

/// Shows every exercise in the workout, in order, marking which are done,
/// which is in progress, and which are still upcoming — so you can see at a
/// glance what's completed and what's left as you move through a session.
///
/// Collapsible to save vertical space: collapsed, it shows just the current
/// exercise's row.
class WorkoutOverview extends StatefulWidget {
  const WorkoutOverview({super.key, required this.app, required this.tmpl, required this.session});

  final WorkoutAppState app;
  final WorkoutTemplate tmpl;
  final WorkoutSession session;

  @override
  State<WorkoutOverview> createState() => _WorkoutOverviewState();
}

class _WorkoutOverviewState extends State<WorkoutOverview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tmpl = widget.tmpl;
    final session = widget.session;

    return PanelBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Workout overview', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (_expanded)
            for (var i = 0; i < tmpl.exercises.length; i++) _row(i)
          else
            _row(session.exIndex),
        ],
      ),
    );
  }

  Widget _row(int index) {
    final tmpl = widget.tmpl;
    final session = widget.session;
    final exercise = widget.app.exerciseAt(tmpl, session, index);
    final isDone = index < session.exIndex;
    final isCurrent = index == session.exIndex;
    final completedSets = isDone ? exercise.sets : (isCurrent ? session.setIndex - 1 : 0);

    final Color color;
    final IconData icon;
    if (isDone) {
      color = AppColors.good;
      icon = Icons.check_circle;
    } else if (isCurrent) {
      color = AppColors.accent;
      icon = Icons.radio_button_checked;
    } else {
      color = AppColors.textMuted;
      icon = Icons.radio_button_unchecked;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              exercise.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isCurrent ? AppColors.text : AppColors.textMuted,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isCurrent ? 'Set ${session.setIndex} of ${exercise.sets}' : '$completedSets/${exercise.sets} sets',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
