import 'package:flutter/material.dart';
import '../app_state.dart';
import '../badges.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/workout_progress_bar.dart';

class SummaryScreen extends StatelessWidget {
  final WorkoutAppState app;
  const SummaryScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final summary = app.summary;
    if (summary == null) return const SizedBox.shrink();
    final diff = summary.targetSeconds - summary.durationSeconds;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Text(
                  summary.onPace ? 'Finished on pace' : 'Finished over target',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: summary.onPace ? AppColors.good : AppColors.danger,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatDuration(summary.durationSeconds)} of a ${formatDuration(summary.targetSeconds)} target '
                  '${diff >= 0 ? '(${formatDuration(diff)} to spare)' : '(${formatDuration(-diff)} over)'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                PanelBox(
                  child: WorkoutProgressBar(
                    targetSeconds: summary.targetSeconds,
                    elapsedSeconds: summary.durationSeconds,
                    fillColor: summary.onPace ? AppColors.good : AppColors.danger,
                    completedExercises: summary.completedExercises,
                  ),
                ),
                const SizedBox(height: 16),
                PanelBox(
                  child: Column(
                    children: [
                      Text(
                        '+${summary.xpEarned} XP',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                      const SizedBox(height: 8),
                      _row('Base', summary.baseXp),
                      _row('Speed bonus', summary.speedBonus),
                      _row('Streak bonus (${summary.streak} days)', summary.streakBonus),
                    ],
                  ),
                ),
                if (summary.unlockedNow.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PanelBox(
                    child: Column(
                      children: [
                        const Text('New badges', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(height: 10),
                        _NewBadgesSection(badges: summary.unlockedNow),
                      ],
                    ),
                  ),
                ],
                if (app.canSaveTemplate(summary.templateId)) ...[
                  const SizedBox(height: 16),
                  PanelBox(
                    child: Column(
                      children: [
                        const Text(
                          "Enjoyed the session?",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 10),
                        SecondaryButton(
                          onPressed: () => app.saveTemplateToMyWorkouts(summary.templateId),
                          child: const Text('Add to workouts'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Pinned so the way back to the app is always reachable without
        // scrolling, however much summary content is above it.
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: PrimaryButton(
              onPressed: () => app.dismissSummary(),
              child: const Text('Done'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text('+$value', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Shows newly-earned badges collapsed to a single row — as many as fit,
/// with a "+N" tile standing in for the rest — and expands to the full set
/// on tap, so a big haul doesn't push the Done button down the screen.
class _NewBadgesSection extends StatefulWidget {
  const _NewBadgesSection({required this.badges});

  final List<WorkoutBadge> badges;

  @override
  State<_NewBadgesSection> createState() => _NewBadgesSectionState();
}

class _NewBadgesSectionState extends State<_NewBadgesSection> {
  bool _expanded = false;

  static const _itemWidth = 80.0;
  static const _spacing = 16.0;

  @override
  Widget build(BuildContext context) {
    final badges = widget.badges;

    if (_expanded) {
      return Column(
        children: [
          Wrap(
            spacing: _spacing,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: badges.map(_badgeTile).toList(),
          ),
          TextButton(
            onPressed: () => setState(() => _expanded = false),
            child: const Text('Show less'),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final perItem = _itemWidth + _spacing;
        final fits = ((constraints.maxWidth + _spacing) / perItem).floor().clamp(1, badges.length);
        final overflow = badges.length - fits;
        // If everything fits on one line already, there's nothing to
        // collapse — show them all with no "+N" tile or expand option.
        final visibleCount = overflow > 0 ? fits - 1 : fits;

        return SizedBox(
          height: 90,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < visibleCount; i++) ...[
                if (i > 0) const SizedBox(width: _spacing),
                _badgeTile(badges[i]),
              ],
              if (overflow > 0) ...[
                if (visibleCount > 0) const SizedBox(width: _spacing),
                SizedBox(
                  width: _itemWidth,
                  child: InkWell(
                    onTap: () => setState(() => _expanded = true),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.textMuted, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '+${overflow + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('Show all', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _badgeTile(WorkoutBadge badge) {
    return SizedBox(
      width: _itemWidth,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.accent, width: 2)),
            child: Icon(badge.icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(height: 6),
          Text(badge.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.text)),
        ],
      ),
    );
  }
}
