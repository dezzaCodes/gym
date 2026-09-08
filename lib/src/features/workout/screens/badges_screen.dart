import 'package:flutter/material.dart';
import '../app_state.dart';
import '../badges.dart';
import '../theme.dart';

/// The full badge catalog, grouped by category — reached from the Stats
/// screen's badges preview via "See all badges".
class BadgesScreen extends StatelessWidget {
  final WorkoutAppState app;
  const BadgesScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final earnedIds = app.data.profile.badges.toSet();
    final earnedCount = BadgeCatalog.all.where((b) => earnedIds.contains(b.id)).length;

    final categories = <String>{};
    for (final badge in BadgeCatalog.all) {
      categories.add(badge.category);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.text),
                onPressed: () => app.goTo(Screen.stats),
              ),
              const Text('Badges', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$earnedCount/${BadgeCatalog.all.length}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final category in categories) ...[
            PanelBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: BadgeCatalog.all.where((b) => b.category == category).map((badge) {
                      final earned = earnedIds.contains(badge.id);
                      return SizedBox(
                        width: 64,
                        child: Opacity(
                          opacity: earned ? 1 : 0.35,
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: earned ? AppColors.accent : AppColors.border, width: 2),
                                ),
                                child: Icon(badge.icon, color: earned ? AppColors.accent : AppColors.textMuted, size: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                badge.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
