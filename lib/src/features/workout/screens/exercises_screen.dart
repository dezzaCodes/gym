import 'package:flutter/material.dart';
import '../app_state.dart';
import '../exercise_library.dart';
import '../theme.dart';

/// A browsable glossary of every exercise in the library, grouped by
/// muscle group — tap one to see its instructional gif and tips.
class ExercisesScreen extends StatelessWidget {
  final WorkoutAppState app;
  const ExercisesScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.text),
                onPressed: () => app.goTo(Screen.workouts),
              ),
              const Text('Exercises', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
            ],
          ),
          const SizedBox(height: 8),
          for (final group in MuscleGroup.values) ...[
            PanelBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                  const SizedBox(height: 4),
                  for (final name in ExerciseLibrary.byGroup[group] ?? const <String>[])
                    _row(context, name),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String name) {
    final favorite = app.isExerciseFavorite(name);
    return InkWell(
      onTap: () => app.openExerciseDetail(name),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(name, style: const TextStyle(fontSize: 14, color: AppColors.text)),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                favorite ? Icons.star : Icons.star_border,
                size: 20,
                color: favorite ? AppColors.accent : AppColors.textMuted,
              ),
              onPressed: () => app.toggleFavoriteExercise(name),
            ),
          ],
        ),
      ),
    );
  }
}
