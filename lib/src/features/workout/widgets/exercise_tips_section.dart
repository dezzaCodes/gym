import 'package:flutter/material.dart';
import '../exercise_tips.dart';
import '../exercise_tips_data.dart';
import '../theme.dart';

/// An exercise's form guidance: "How to perform", "Tips", and "Common
/// mistakes" sourced from fitnessprogramer.com when available, falling
/// back to the built-in tip bullets for exercises without scraped
/// content.
class ExerciseTipsSection extends StatelessWidget {
  final String exerciseName;
  const ExerciseTipsSection({super.key, required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    final entry = exerciseTipsData[exerciseName];
    if (entry == null || entry.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: ExerciseTips.tips(exerciseName).map((tip) => _bullet(tip, AppColors.textMuted)).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.howTo.isNotEmpty) ...[
          const Text(
            'How to perform',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < entry.howTo.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}.  ', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(entry.howTo[i], style: const TextStyle(fontSize: 13, color: AppColors.text))),
                ],
              ),
            ),
        ],
        if (entry.tips.isNotEmpty) ...[
          if (entry.howTo.isNotEmpty) const SizedBox(height: 12),
          const Text('Tips', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.good)),
          const SizedBox(height: 4),
          for (final tip in entry.tips) _bullet(tip, AppColors.good),
        ],
        if (entry.mistakes.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Common mistakes',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger),
          ),
          const SizedBox(height: 4),
          for (final mistake in entry.mistakes) _bullet(mistake, AppColors.danger),
        ],
      ],
    );
  }

  Widget _bullet(String text, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: TextStyle(color: dotColor)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.text))),
        ],
      ),
    );
  }
}
