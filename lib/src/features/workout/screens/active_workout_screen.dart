import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../exercise_tips.dart';
import '../widgets/rest_skip_button.dart';
import '../widgets/exercise_chart.dart';
import '../widgets/workout_overview.dart';

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
                SizedBox(
                  height: 8,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: math.min(1.0, timeFraction),
                          minHeight: 8,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(paceColor),
                        ),
                      ),
                      // A tick for each exercise finished so far, at the
                      // point in the bar where it ended — a reference for
                      // spotting which one ate the most time (the widest
                      // gap between ticks).
                      for (final done in session.completedExercises)
                        Align(
                          alignment: Alignment(-1 + 2 * math.min(1.0, done.endElapsed / math.max(targetSeconds, 1)), 0),
                          child: Container(width: 1.5, height: 12, color: AppColors.background),
                        ),
                      // Marks how far you actually are through the workout,
                      // by completed sets weighted by each exercise's own
                      // expected time — the time fill passing this line
                      // means you're running behind. Animated so it visibly
                      // slides to its new position each time a set is
                      // completed, rather than jumping.
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        alignment: Alignment(-1 + 2 * currentPace, 0),
                        child: Container(width: 2, height: 12, color: AppColors.text),
                      ),
                    ],
                  ),
                ),
                if (session.completedExercises.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 12,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const labelStyle = TextStyle(fontSize: 9, color: AppColors.textMuted);
                        final children = <Widget>[];
                        for (final done in session.completedExercises) {
                          final label = formatDuration(done.durationSeconds);
                          final labelWidth = (TextPainter(
                            text: TextSpan(text: label, style: labelStyle),
                            textDirection: TextDirection.ltr,
                          )..layout())
                              .width;
                          // Center the label under the middle of the time
                          // this exercise actually took, but skip it if the
                          // segment is too narrow to fit it without
                          // overlapping its neighbors.
                          final segmentWidth = constraints.maxWidth * done.durationSeconds / math.max(targetSeconds, 1);
                          if (labelWidth + 4 > segmentWidth) continue;
                          final startFraction =
                              math.max(0, done.endElapsed - done.durationSeconds) / math.max(targetSeconds, 1);
                          final endFraction = math.min(1.0, done.endElapsed / math.max(targetSeconds, 1));
                          final midFraction = (startFraction + endFraction) / 2;
                          final maxLeft = math.max(0.0, constraints.maxWidth - labelWidth);
                          final left = (constraints.maxWidth * midFraction - labelWidth / 2).clamp(0.0, maxLeft);
                          children.add(Positioned(left: left, child: Text(label, style: labelStyle)));
                        }
                        return Stack(children: children);
                      },
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      paceLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: paceColor),
                    ),
                  ),
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
                      children: [
                        const Text('Working set', style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
                        const SizedBox(height: 12),
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
                      ...ExerciseTips.tips(ex.name).map(
                        (tip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('•  ', style: TextStyle(color: AppColors.textMuted)),
                              Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, color: AppColors.text))),
                            ],
                          ),
                        ),
                      ),
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
      ],
    );
  }
}
