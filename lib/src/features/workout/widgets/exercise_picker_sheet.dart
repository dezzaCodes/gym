import 'package:flutter/material.dart';
import '../exercise_library.dart';
import '../theme.dart';

/// Opens a searchable, muscle-group-grouped picker and resolves to the
/// chosen exercise name, or null if the sheet was dismissed.
Future<String?> showExercisePicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.panel,
    isScrollControlled: true,
    builder: (context) => const _ExercisePickerSheet(),
  );
}

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet();

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final groups = MuscleGroup.values
        .map((group) {
          final names = ExerciseLibrary.byGroup[group]!
              .where((name) => query.isEmpty || name.toLowerCase().contains(query))
              .toList();
          return MapEntry(group, names);
        })
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Choose an exercise',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.text),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('exercisePickerSearch'),
                autofocus: false,
                style: const TextStyle(color: AppColors.text),
                decoration: ironFieldDecoration(hint: 'Search exercises'),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: groups.isEmpty
                  ? const Center(
                      child: Text(
                        'No exercises match your search.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        for (final entry in groups) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              entry.key.label,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accent),
                            ),
                          ),
                          ...entry.value.map(
                            (name) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(name, style: const TextStyle(color: AppColors.text)),
                              onTap: () => Navigator.pop(context, name),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
