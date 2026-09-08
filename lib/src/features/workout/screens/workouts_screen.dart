import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';

class WorkoutsScreen extends StatelessWidget {
  final WorkoutAppState app;
  const WorkoutsScreen({super.key, required this.app});

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Delete this workout?', style: TextStyle(color: AppColors.text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true) app.deleteTemplate(id);
  }

  @override
  Widget build(BuildContext context) {
    // Randomly generated workouts stay off this list until explicitly
    // saved (from the summary screen or Stats' recent sessions).
    final savedTemplates = app.data.templates.where((t) => !t.isTemporary).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your workouts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 8),
          ...savedTemplates.map((t) {
            final isActive = t.id == app.data.activeTemplateId;
            final totalSets = t.exercises.fold<int>(0, (a, e) => a + e.sets);
            final canDelete = savedTemplates.length > 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PanelBox(
                borderColor: isActive ? AppColors.accent : AppColors.border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => app.selectTemplate(t.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                              if (isActive) const Text('Selected', style: TextStyle(fontSize: 11, color: AppColors.accent)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${t.exercises.length} exercises, $totalSets sets, ${t.targetMinutes} min target',
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            onPressed: () => app.startTemplateNow(t.id),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.play_arrow, size: 16), SizedBox(width: 6), Text('Start')],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune, color: AppColors.text),
                          onPressed: () => app.openEditForTemplate(t.id, Screen.workouts),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: canDelete ? AppColors.danger : AppColors.border),
                          onPressed: canDelete ? () => _confirmDelete(context, t.id) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          DashedButton(
            onPressed: () => app.newTemplateAndEdit(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.add, size: 16), SizedBox(width: 6), Text('New workout')],
            ),
          ),
        ],
      ),
    );
  }
}
