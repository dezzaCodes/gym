import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

/// The time-vs-pace bar: a fill for how far through the target time the
/// workout is, with each exercise's overall time labeled above the bar
/// and, inside the bar itself, the individual set and rest times placed
/// exactly where they happened — a reference for spotting which set or
/// rest ate the most time — plus, while a workout is actively running,
/// an animated marker for current pace.
///
/// The rest taken right after an exercise's last set is credited to that
/// exercise's own section (you're resting *from* it), not the next one,
/// so an exercise's section runs from its first set to the start of the
/// next exercise's first set.
///
/// Passing only [completedExercises] with no live parameters renders a
/// static "final" bar, suitable for a finished workout's summary.
class WorkoutProgressBar extends StatelessWidget {
  final int targetSeconds;
  final int elapsedSeconds;
  final Color fillColor;
  final List<CompletedExercise> completedExercises;

  /// Live-only: the animated current-pace marker and its status label.
  /// Omit both for a static bar.
  final double? currentPaceFraction;
  final String? paceLabel;
  final Color? paceLabelColor;

  const WorkoutProgressBar({
    super.key,
    required this.targetSeconds,
    required this.elapsedSeconds,
    required this.fillColor,
    required this.completedExercises,
    this.currentPaceFraction,
    this.paceLabel,
    this.paceLabelColor,
  });

  static const _barHeight = 20.0;

  @override
  Widget build(BuildContext context) {
    final timeFraction = targetSeconds > 0 ? elapsedSeconds / targetSeconds : 0.0;

    final workStarts = [for (final done in completedExercises) done.endElapsed - done.durationSeconds];

    // Chunks within each exercise's section: its own sets' work and rest
    // times, plus (folded into this exercise rather than the next) the
    // rest taken after its last set, right up to the point the next
    // exercise's first set begins.
    final chunks = <({int start, int end, String label, bool isRest})>[];
    final sectionLabels = <({int start, int end, String label})>[];
    for (var i = 0; i < completedExercises.length; i++) {
      final done = completedExercises[i];
      var t = workStarts[i];
      for (var j = 0; j < done.sets.length; j++) {
        final set = done.sets[j];
        if (j > 0) {
          final restBefore = set.restSeconds ?? 0;
          if (restBefore > 0) {
            chunks.add((start: t, end: t + restBefore, label: formatDuration(restBefore), isRest: true));
            t += restBefore;
          }
        }
        final work = set.setSeconds ?? 0;
        if (work > 0) {
          chunks.add((start: t, end: t + work, label: formatDuration(work), isRest: false));
          t += work;
        }
      }

      // For whichever exercise is the most recent one (no next exercise's
      // entry yet), extend its trailing rest live up to the current overall
      // elapsed time — otherwise the rest taken before the next exercise's
      // first set wouldn't show as this exercise's until that set actually
      // starts, instead of growing live the moment the rest itself starts.
      final sectionEnd = i < completedExercises.length - 1 ? workStarts[i + 1] : math.max(done.endElapsed, elapsedSeconds);
      if (sectionEnd > t) {
        chunks.add((start: t, end: sectionEnd, label: formatDuration(sectionEnd - t), isRest: true));
      }
      sectionLabels.add((
        start: workStarts[i],
        end: sectionEnd,
        label: '${done.exerciseName} · ${formatDuration(sectionEnd - workStarts[i])}',
      ));
    }

    return Column(
      children: [
        if (sectionLabels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: SizedBox(
              height: 14,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const labelStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textMuted);
                  return Stack(
                    children: _buildSectionBrackets(sectionLabels, constraints.maxWidth, labelStyle),
                  );
                },
              ),
            ),
          ),
        SizedBox(
          height: _barHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const chunkLabelStyle = TextStyle(fontSize: 7, color: AppColors.background);
              final chunkLabelChildren = _placeLabels(
                chunks.map((c) => (start: c.start, end: c.end, label: c.label)).toList(),
                constraints.maxWidth,
                chunkLabelStyle,
                verticalPad: false,
              );

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    // Ticks arrive once a second from the parent's timer, which
                    // would otherwise make the fill jump in visible steps; this
                    // eases each jump into a smooth glide, the same duration and
                    // curve already used for the pace marker below.
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: math.min(1.0, timeFraction), end: math.min(1.0, timeFraction)),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (context, value, child) => LinearProgressIndicator(
                        value: value,
                        minHeight: _barHeight,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(fillColor),
                      ),
                    ),
                  ),
                  // Dims each rest stretch exactly where it happened —
                  // between sets, or after an exercise's last one.
                  for (final chunk in chunks.where((c) => c.isRest))
                    Positioned(
                      left: constraints.maxWidth * chunk.start / math.max(targetSeconds, 1),
                      width: constraints.maxWidth *
                          (math.min(chunk.end, targetSeconds) - chunk.start) /
                          math.max(targetSeconds, 1),
                      top: 0,
                      bottom: 0,
                      child: ColoredBox(color: AppColors.background.withValues(alpha: 0.55)),
                    ),
                  // A divider at the end of each exercise's section
                  // (after its trailing rest), where the next one's
                  // first set begins.
                  for (final section in sectionLabels)
                    Align(
                      alignment: Alignment(-1 + 2 * math.min(1.0, section.end / math.max(targetSeconds, 1)), 0),
                      child: Container(width: 1, height: _barHeight, color: AppColors.background.withValues(alpha: 0.4)),
                    ),
                  ...chunkLabelChildren,
                  if (currentPaceFraction != null)
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      alignment: Alignment(-1 + 2 * currentPaceFraction!, 0),
                      child: Container(width: 2, height: _barHeight + 4, color: AppColors.text),
                    ),
                ],
              );
            },
          ),
        ),
        if (chunks.any((c) => c.isRest))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 8, height: 8, color: fillColor),
                const SizedBox(width: 4),
                const Text('Exercise', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(width: 12),
                // Matches how a rest stretch actually looks on the bar:
                // the same fill color, dimmed by the same overlay.
                Stack(
                  children: [
                    Container(width: 8, height: 8, color: fillColor),
                    Container(width: 8, height: 8, color: AppColors.background.withValues(alpha: 0.55)),
                  ],
                ),
                const SizedBox(width: 4),
                const Text('Rest', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        if (currentPaceFraction != null && paceLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              height: 16,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final paceLabelStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: paceLabelColor);
                  final labelWidth = (TextPainter(
                    text: TextSpan(text: paceLabel, style: paceLabelStyle),
                    textDirection: TextDirection.ltr,
                  )..layout())
                      .width;
                  final maxLeft = math.max(0.0, constraints.maxWidth - labelWidth);
                  final left = (constraints.maxWidth * currentPaceFraction! - labelWidth / 2).clamp(0.0, maxLeft);
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        left: left,
                        child: Text(paceLabel!, style: paceLabelStyle),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  /// Centers each range's label in the middle of its own span, greedily
  /// left-to-right, dropping one only if it would actually collide with
  /// the last label placed — free space around a narrow range can still
  /// fit its label even if the range itself couldn't contain it alone.
  List<Widget> _placeLabels(
    List<({int start, int end, String label})> ranges,
    double maxWidth,
    TextStyle style, {
    bool verticalPad = true,
  }) {
    final children = <Widget>[];
    double? lastRight;
    for (final range in ranges) {
      final labelWidth = (TextPainter(text: TextSpan(text: range.label, style: style), textDirection: TextDirection.ltr)
            ..layout())
          .width;
      final startFraction = range.start / math.max(targetSeconds, 1);
      final endFraction = math.min(1.0, range.end / math.max(targetSeconds, 1));
      final midFraction = (startFraction + endFraction) / 2;
      final maxLeft = math.max(0.0, maxWidth - labelWidth);
      final left = (maxWidth * midFraction - labelWidth / 2).clamp(0.0, maxLeft);
      if (lastRight != null && left < lastRight + 2) continue;
      lastRight = left + labelWidth;
      final text = Text(range.label, style: style);
      children.add(
        Positioned(
          left: left,
          top: verticalPad ? null : 0,
          bottom: verticalPad ? null : 0,
          child: verticalPad ? text : Center(child: text),
        ),
      );
    }
    return children;
  }

  /// A bracket — a horizontal line with a small tick at each end — under
  /// each exercise's section, marking exactly which stretch of the bar
  /// (and which chunks within it) belongs to it. The line passes through
  /// the same row as the label rather than sitting in a separate row
  /// below it, but is split around the label's own width so it doesn't
  /// run through the text itself.
  List<Widget> _buildSectionBrackets(
    List<({int start, int end, String label})> sections,
    double maxWidth,
    TextStyle labelStyle,
  ) {
    const lineColor = AppColors.textMuted;
    const lineY = 7.0;
    const tickTop = 3.0;
    const tickHeight = 8.0;

    final children = <Widget>[];
    double? lastLabelRight;
    for (final section in sections) {
      final sectionLeft = maxWidth * section.start / math.max(targetSeconds, 1);
      final sectionRight = maxWidth * math.min(section.end, targetSeconds) / math.max(targetSeconds, 1);

      final labelWidth = (TextPainter(
        text: TextSpan(text: section.label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout())
          .width;
      final midFraction = (section.start / math.max(targetSeconds, 1) +
              math.min(section.end, targetSeconds) / math.max(targetSeconds, 1)) /
          2;
      final maxLabelLeft = math.max(0.0, maxWidth - labelWidth);
      final labelLeft = (maxWidth * midFraction - labelWidth / 2).clamp(0.0, maxLabelLeft);
      final labelFits = lastLabelRight == null || labelLeft >= lastLabelRight + 2;

      Widget line(double left, double right) =>
          Positioned(left: left, top: lineY, child: Container(width: math.max(0.0, right - left), height: 1, color: lineColor));

      Widget tick(double left) =>
          Positioned(left: left, top: tickTop, child: Container(width: 1, height: tickHeight, color: lineColor));

      if (labelFits) {
        const gap = 3.0;
        final labelRight = labelLeft + labelWidth;
        children.add(line(sectionLeft, math.max(sectionLeft, labelLeft - gap)));
        children.add(line(math.min(sectionRight, labelRight + gap), sectionRight));
        children.add(Positioned(left: labelLeft, top: 1, child: Text(section.label, style: labelStyle)));
        lastLabelRight = labelRight;
        // A long label can spill past its own section's edge — skip the
        // boundary tick there instead of drawing it through the text.
        if (sectionLeft <= labelLeft - gap) children.add(tick(sectionLeft));
        if (sectionRight - 1 >= labelRight + gap) children.add(tick(sectionRight - 1));
      } else {
        children.add(line(sectionLeft, sectionRight));
        children.add(tick(sectionLeft));
        children.add(tick(sectionRight - 1));
      }
    }
    return children;
  }
}
