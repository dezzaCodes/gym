import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/exercise_gif_preview.dart';
import '../widgets/exercise_tips_section.dart';
import '../widgets/rest_skip_button.dart';
import '../widgets/exercise_chart.dart';
import '../widgets/workout_overview.dart';
import '../widgets/workout_progress_bar.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  final WorkoutAppState app;
  const ActiveWorkoutScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final session = app.session;
    if (session == null) return const SizedBox.shrink();

    final tmpl = app.templateById(session.templateId);
    final ex = app.exerciseAt(tmpl, session, session.exIndex);
    final targetSeconds = tmpl.targetMinutes * 60;
    final timeFraction = targetSeconds > 0 ? session.elapsed / targetSeconds : 0.0;
    final currentPace = app.currentPaceFraction();

    Color paceColor = AppColors.good;
    String paceLabel = 'On pace';
    if (session.completedSets > 0) {
      if (timeFraction > currentPace + 0.15) {
        paceColor = AppColors.danger;
        paceLabel = 'Behind pace';
      } else if (timeFraction > currentPace + 0.02) {
        paceColor = AppColors.warn;
        paceLabel = 'Slipping';
      }
    }

    final remaining = ex.restSeconds - session.restElapsed;
    final exHistory = app.exerciseHistoryIncludingToday(ex.name);
    final suggestion = app.progressionSuggestion(ex.name, session.setIndex);
    final isWorking = session.phase == SessionPhase.working;

    // The bar's rest/exercise split only has data for exercises that have
    // fully finished. So it can update live as the current one goes,
    // rather than jumping in all at once once every set is done, stand
    // in a partial entry for it from whatever sets have been logged so
    // far this exercise, plus — once the set actually in progress has
    // moved from resting to working — a synthetic entry for it so that
    // time renders as work instead of continuing to be painted as the
    // rest that preceded it.
    final currentExerciseLogs = session.logs.where((l) => l.exerciseName == ex.name).toList();
    final liveSets = [
      ...currentExerciseLogs.map((l) => SetEntry(
            setNumber: l.setNumber,
            weight: l.weight,
            reps: l.reps,
            setSeconds: l.setSeconds,
            restSeconds: l.restSeconds,
          )),
      if (isWorking)
        SetEntry(
          setNumber: currentExerciseLogs.length + 1,
          weight: null,
          reps: null,
          setSeconds: session.elapsed - session.setStartElapsed,
          restSeconds: session.pendingRestSeconds > 0 ? session.pendingRestSeconds : null,
        ),
    ];
    final liveCompletedExercises = [
      ...session.completedExercises,
      if (liveSets.isNotEmpty)
        CompletedExercise(
          exerciseName: ex.name,
          durationSeconds: session.elapsed - session.exerciseStartElapsed,
          endElapsed: session.elapsed,
          sets: liveSets,
        ),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                // 1. Overall status: timer, time-vs-pace bar, and the full
                // workout at a glance — always visible regardless of what
                // you're doing right now.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.close, color: AppColors.text), onPressed: app.abandonWorkout),
                    Column(
                      children: [
                        Text(tmpl.name, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          '${formatDuration(session.elapsed)} / ${tmpl.targetMinutes}:00',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(session.paused ? Icons.play_arrow : Icons.pause, color: AppColors.text),
                      onPressed: app.togglePause,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                WorkoutProgressBar(
                  targetSeconds: targetSeconds,
                  elapsedSeconds: session.elapsed,
                  fillColor: paceColor,
                  completedExercises: liveCompletedExercises,
                  currentPaceFraction: currentPace,
                  paceLabel: paceLabel,
                  paceLabelColor: paceColor,
                ),
                const SizedBox(height: 16),
                WorkoutOverview(app: app, tmpl: tmpl, session: session),

                // 2. The input fields right up top when there's a set to
                // log, so they're visible without scrolling. While resting,
                // the countdown lives on the pinned Skip rest button below
                // instead, so this section is skipped entirely.
                const SizedBox(height: 16),
                if (isWorking) ...[
                  PanelBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Working set', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        const Text(
                          'Logging weight and reps unlocks your progress chart, weight-up '
                          'suggestions, and PR badges for this exercise.',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Weight (optional)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    key: ValueKey('weight_${session.exIndex}_${session.setIndex}'),
                                    initialValue: session.currentWeight,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(color: AppColors.text),
                                    decoration: ironFieldDecoration(hint: '—'),
                                    onChanged: app.updateCurrentWeight,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Reps (optional)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    key: ValueKey('reps_${session.exIndex}_${session.setIndex}'),
                                    initialValue: session.currentReps,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: AppColors.text),
                                    decoration: ironFieldDecoration(hint: '—'),
                                    onChanged: app.updateCurrentReps,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                // Offered whenever the upcoming set is an exercise's first —
                // whether you're actively working it or still resting from
                // the previous exercise's last set, since by then this is
                // already the exercise you're about to do.
                if (app.canSwapCurrentExercise()) ...[
                  const SizedBox(height: 10),
                  SecondaryButton(
                    onPressed: app.swapCurrentExercise,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.swap_horiz, size: 16), SizedBox(width: 6), Text('Swap exercise')],
                    ),
                  ),
                  const SizedBox(height: 8),
                  DangerOutlinedButton(
                    onPressed: app.markCurrentExerciseCantDo,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block, size: 16),
                        SizedBox(width: 6),
                        Text("Can't do this"),
                      ],
                    ),
                  ),
                ],

                // 3. Supplementary context for the set you're about to do —
                // useful, but not required to act, so it sits below the
                // input fields rather than pushing them down.
                if (suggestion != null) ...[
                  const SizedBox(height: 16),
                  PanelBox(
                    borderColor: AppColors.accent,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.show_chart, color: AppColors.accent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(suggestion, style: const TextStyle(fontSize: 13, color: AppColors.text))),
                      ],
                    ),
                  ),
                ],

                // 4. Form cues for the current exercise — shown whether
                // you're actively working the set or resting before it.
                const SizedBox(height: 16),
                PanelBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tips for ${ex.name}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      ExerciseGifPreview(exerciseName: ex.name),
                      const SizedBox(height: 8),
                      ExerciseTipsSection(exerciseName: ex.name),
                    ],
                  ),
                ),

                // 5. Historical detail — the least time-critical content, so
                // it's last.
                if (exHistory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PanelBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('History for ${ex.name}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        ExerciseChart(history: exHistory),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Pinned above the bottom nav so the decisive action for whichever
        // phase you're in — finishing a set, or moving past rest — is
        // always reachable without scrolling.
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              height: 48,
              child: isWorking
                  ? PrimaryButton(
                      onPressed: app.completeSet,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.check), SizedBox(width: 8), Text('Finish set')],
                      ),
                    )
                  : RestSkipButton(
                      remaining: remaining,
                      total: ex.restSeconds,
                      onPressed: app.skipRest,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
