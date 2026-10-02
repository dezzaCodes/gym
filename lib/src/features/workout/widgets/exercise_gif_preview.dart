import 'package:flutter/material.dart';
import '../exercise_gifs.dart';
import '../theme.dart';

/// The instructional gif for an exercise, if one exists in
/// [exerciseGifUrls]. Renders nothing when there's no match, and a small
/// fallback message if the bundled asset ever fails to load.
class ExerciseGifPreview extends StatelessWidget {
  final String exerciseName;
  final double height;

  const ExerciseGifPreview({super.key, required this.exerciseName, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final url = exerciseGifUrls[exerciseName];
    if (url == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        url,
        // Re-key on exercise name so switching exercises swaps the image
        // instead of reusing stale state from the previous one.
        key: ValueKey(exerciseName),
        width: double.infinity,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          alignment: Alignment.center,
          color: AppColors.panelAlt,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 24),
              SizedBox(height: 6),
              Text("Couldn't load the preview", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
