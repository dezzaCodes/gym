import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/exercise_gif_preview.dart';
import '../widgets/exercise_tips_section.dart';

/// A single exercise's instructional gif and form tips, with a favorite
/// toggle — reached by tapping an exercise in the glossary.
class ExerciseDetailScreen extends StatelessWidget {
  final WorkoutAppState app;
  const ExerciseDetailScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final name = app.selectedExerciseName;
    if (name == null) return const SizedBox.shrink();
    final favorite = app.isExerciseFavorite(name);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.text),
                onPressed: app.closeExerciseDetail,
              ),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
                ),
              ),
              IconButton(
                icon: Icon(
                  favorite ? Icons.star : Icons.star_border,
                  color: favorite ? AppColors.accent : AppColors.textMuted,
                ),
                onPressed: () => app.toggleFavoriteExercise(name),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PanelBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExerciseGifPreview(exerciseName: name),
                const SizedBox(height: 8),
                ExerciseTipsSection(exerciseName: name),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
