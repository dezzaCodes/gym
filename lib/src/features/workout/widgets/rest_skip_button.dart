import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';

/// The pinned rest-phase action button: a fill that drains smoothly from
/// full width down to empty as the rest period runs out, with the
/// countdown shown directly on the button itself so it's visible without
/// scrolling up to the workout overview. Once time's up it becomes a
/// "Start next set" button styled the same as the danger-outlined "Can't
/// do this" button, signaling it's time to move on.
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
        child: const Text('Start next set'),
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
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  tween: Tween<double>(begin: pct, end: pct),
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
