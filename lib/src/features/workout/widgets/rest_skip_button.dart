import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';

/// The pinned rest-phase action button: a fill that eases smoothly toward
/// wherever [remaining] currently is, re-syncing on every tick rather than
/// running one long animation for the whole rest period on its own clock.
/// The countdown is shown directly on the button itself so it's visible
/// without scrolling up to the workout overview. Once time's up it becomes
/// a "Start next set" button styled the same as the danger-outlined "Can't
/// do this" button, signaling it's time to move on.
///
/// A single long real-time animation (the previous approach) can drift or
/// freeze if the tab loses animation frames for a while — browsers pause
/// them for a hidden/unfocused tab — and, unlike a periodic timer tick,
/// never gets a chance to self-correct once frames resume. Re-deriving the
/// fill from [remaining]/[total] every tick avoids that entirely: it's
/// always drawn from the same already-correct value the countdown text
/// uses, the same fix already applied to the top progress bar's fill.
class RestSkipButton extends StatelessWidget {
  final int remaining;
  final int total;
  final VoidCallback onPressed;

  const RestSkipButton({super.key, required this.remaining, required this.total, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (remaining < 0) {
      return DangerOutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('Start next set', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(width: 8),
            Text(formatDuration(remaining), style: const TextStyle(fontSize: 13, color: AppColors.danger)),
          ],
        ),
      );
    }

    final pct = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;
    final fillColor = pct < 0.25 ? AppColors.warn : AppColors.good;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: AppColors.panel,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: pct, end: pct),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, value, child) => FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    heightFactor: 1,
                    alignment: Alignment.centerLeft,
                    child: ColoredBox(color: fillColor.withValues(alpha: 0.35)),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: onPressed,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'Skip rest',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text),
                    ),
                    const SizedBox(width: 8),
                    Text(formatDuration(remaining), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
