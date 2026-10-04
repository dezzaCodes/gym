import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/exercise_chart.dart';

class ProgressScreen extends StatefulWidget {
  final WorkoutAppState app;
  const ProgressScreen({super.key, required this.app});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String selected = '';

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final exerciseNames = app.data.exerciseHistory.keys.toList()..sort();

    if (exerciseNames.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
            SizedBox(height: 16),
            PanelBox(
              child: Text(
                'Log a weight or rep count during a set to start tracking progress here.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    if (selected.isEmpty || !exerciseNames.contains(selected)) {
      selected = exerciseNames.first;
    }

    final instances = app.data.exerciseHistory[selected] ?? [];
    final recent = instances.reversed.take(6).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: exerciseNames.map((name) {
                final isSelected = name == selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(name),
                    selected: isSelected,
                    onSelected: (_) => setState(() => selected = name),
                    selectedColor: AppColors.accent,
                    backgroundColor: Colors.transparent,
                    labelStyle: TextStyle(color: isSelected ? AppColors.background : AppColors.textMuted, fontSize: 13),
                    shape: StadiumBorder(side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          PanelBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sets over time', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                ExerciseChart(history: instances),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PanelBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recent sessions', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                ...recent.map(
                  (inst) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(formatShortDate(inst.date), style: const TextStyle(fontSize: 13, color: AppColors.text)),
                            if (inst.durationSeconds != null)
                              Text(formatDuration(inst.durationSeconds!), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          ],
                        ),
                        Text(
                          inst.sets.map(formatSetLog).join(', '),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
