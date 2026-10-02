import 'package:flutter/material.dart';
import '../app_state.dart';
import '../exercise_library.dart';
import '../theme.dart';
import '../widgets/random_workout_sheet.dart';

class HomeScreen extends StatelessWidget {
  final WorkoutAppState app;
  const HomeScreen({super.key, required this.app});

  Future<void> _generateRandomWorkout(BuildContext context) async {
    final request = await showRandomWorkoutSheet(context);
    if (request == null) return;
    final id = app.generateRandomWorkout(request);
    // Makes the generated workout the current one, shown on this screen —
    // from here the user reviews it and taps Start workout when ready.
    app.selectTemplate(id);
  }

  @override
  Widget build(BuildContext context) {
    final levelInfo = app.levelInfo();
    final activeTemplate = app.templateById(app.data.activeTemplateId);
    final totalSets = activeTemplate.exercises.fold<int>(0, (a, e) => a + e.sets);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Level ${levelInfo.level}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                              Text('${app.data.profile.totalXp} XP',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.local_fire_department,
                                  size: 20, color: app.data.profile.streak > 0 ? AppColors.accent : AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text('${app.data.profile.streak}',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: app.data.profile.streak > 0 ? AppColors.accent : AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: levelInfo.into / levelInfo.need,
                          minHeight: 8,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${levelInfo.into}/${levelInfo.need} to level ${levelInfo.level + 1}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PanelBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(activeTemplate.name,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune, color: AppColors.text),
                            onPressed: () => app.openEditForTemplate(activeTemplate.id, Screen.home),
                          ),
                        ],
                      ),
                      Text(
                        '${activeTemplate.exercises.length} exercises, $totalSets sets, ${activeTemplate.targetMinutes} min target',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      ...activeTemplate.exercises.map((ex) {
                        final group = ExerciseLibrary.groupOf(ex.name);
                        // Not offered mid-workout: a session already in
                        // progress has its own (session-only) swap, and
                        // editing the saved plan out from under it here
                        // could desync which exercise it's currently on.
                        final canSwap = app.session == null && app.canSwapTemplateExercise(activeTemplate.id, ex.id);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        ex.name,
                                        style: const TextStyle(fontSize: 14, color: AppColors.text),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (canSwap)
                                      InkWell(
                                        borderRadius: BorderRadius.circular(4),
                                        onTap: () => app.swapTemplateExercise(activeTemplate.id, ex.id),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                          child: Icon(Icons.swap_horiz, size: 16, color: AppColors.textMuted),
                                        ),
                                      ),
                                    if (group != null)
                                      Text(
                                        ' · ${group.label}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                  ],
                                ),
                              ),
                              Text('${ex.sets} sets, ${ex.restSeconds}s rest',
                                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Pinned above the bottom nav so the two primary actions are always
        // reachable without scrolling, however long the exercise list above
        // gets.
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                SecondaryButton(
                  onPressed: () => _generateRandomWorkout(context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shuffle, size: 16),
                      SizedBox(width: 6),
                      Text('Random workout', style: TextStyle(fontWeight: FontWeight.normal)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  onPressed: () => app.startWorkout(),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.play_arrow), SizedBox(width: 8), Text('Start workout')],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
