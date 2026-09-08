import 'package:flutter/material.dart';
import '../app_state.dart';
import '../badges.dart';
import '../models.dart';
import '../theme.dart';

class StatsScreen extends StatelessWidget {
  final WorkoutAppState app;
  const StatsScreen({super.key, required this.app});

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Reset all progress?', style: TextStyle(color: AppColors.text)),
        content: const Text('This cannot be undone.', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true) app.resetAll();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your stats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 16),
          PanelBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBlock('${app.data.profile.sessionCount}', 'Workouts'),
                _statBlock('${app.data.profile.onPaceCount}', 'On pace'),
                _statBlock('${app.data.profile.streak}', 'Streak'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _BadgesSection(app: app),
          const SizedBox(height: 16),
          PanelBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recent sessions', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                if (app.data.history.isEmpty)
                  const Text(
                    'Nothing logged yet. Finish a workout to see it here.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ...app.data.history.map((h) {
                  final canSave = app.canSaveTemplate(h.templateId);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('${h.date} · ${h.templateName}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.text), overflow: TextOverflow.ellipsis),
                            ),
                            Text(formatDuration(h.durationSeconds),
                                style: TextStyle(fontSize: 13, color: h.onPace ? AppColors.good : AppColors.danger)),
                            const SizedBox(width: 8),
                            Text('+${h.xpEarned} XP', style: const TextStyle(fontSize: 13, color: AppColors.accent)),
                          ],
                        ),
                        if (canSave)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => app.saveTemplateToMyWorkouts(h.templateId!),
                              child: const Text('Save to my workouts', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          if (app.data.excludedExercises.isNotEmpty) ...[
            const SizedBox(height: 16),
            PanelBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Excluded exercises', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  const Text(
                    "Never suggested in random workouts or exercise swaps.",
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  ...(app.data.excludedExercises.toList()..sort()).map(
                    (name) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(name, style: const TextStyle(fontSize: 13, color: AppColors.text))),
                          TextButton(
                            onPressed: () => app.includeExercise(name),
                            child: const Text('Include again', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SyncSection(app: app),
          const SizedBox(height: 16),
          SecondaryButton(
            onPressed: () => _confirmReset(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restart_alt, size: 16, color: AppColors.danger),
                SizedBox(width: 8),
                Text('Reset all data', style: TextStyle(color: AppColors.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBlock(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}

/// A compact taste of the badge catalog — earned badges first, then a few
/// upcoming locked ones as a teaser — with a button through to the full
/// [BadgesScreen] rather than dumping all ~100 onto the stats page.
class _BadgesSection extends StatelessWidget {
  final WorkoutAppState app;
  const _BadgesSection({required this.app});

  @override
  Widget build(BuildContext context) {
    final earnedIds = app.data.profile.badges.toSet();
    final earnedCount = BadgeCatalog.all.where((b) => earnedIds.contains(b.id)).length;

    final earned = BadgeCatalog.all.where((b) => earnedIds.contains(b.id));
    final locked = BadgeCatalog.all.where((b) => !earnedIds.contains(b.id));
    final preview = [...earned, ...locked];

    return PanelBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Badges', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              Text('$earnedCount/${BadgeCatalog.all.length}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 68,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const itemWidth = 56.0;
                const spacing = 12.0;
                final fits = ((constraints.maxWidth + spacing) / (itemWidth + spacing)).floor().clamp(1, preview.length);
                final shown = preview.take(fits).toList();
                return Row(
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0) const SizedBox(width: spacing),
                      _badgeIcon(shown[i], earnedIds.contains(shown[i].id)),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            onPressed: () => app.goTo(Screen.badges),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text('See all badges'), SizedBox(width: 6), Icon(Icons.chevron_right, size: 18)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeIcon(WorkoutBadge badge, bool earned) {
    return Opacity(
      opacity: earned ? 1 : 0.35,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: earned ? AppColors.accent : AppColors.border, width: 2),
        ),
        child: Icon(badge.icon, color: earned ? AppColors.accent : AppColors.textMuted, size: 18),
      ),
    );
  }
}

class _SyncSection extends StatefulWidget {
  final WorkoutAppState app;
  const _SyncSection({required this.app});

  @override
  State<_SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends State<_SyncSection> {
  final _emailController = TextEditingController();
  final _linkController = TextEditingController();
  bool _linkSent = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final error = await widget.app.requestSyncLink(email);
    setState(() {
      _busy = false;
      if (error == null) {
        _linkSent = true;
        _message = 'Check your email for a sign-in link, then paste it below.';
      } else {
        _message = error;
      }
    });
  }

  Future<void> _finishSignIn() async {
    final email = _emailController.text.trim();
    final link = _linkController.text.trim();
    if (email.isEmpty || link.isEmpty) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final error = await widget.app.completeSyncLink(email: email, link: link);
    setState(() {
      _busy = false;
      _message = error;
    });
    if (error == null) {
      _linkController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;

    if (!app.syncAvailable) {
      return const PanelBox(
        child: Text(
          'Cross-device sync requires Firebase to be configured for this app.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      );
    }

    return PanelBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sync across devices', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          if (app.signedIn) ...[
            Row(
              children: [
                const Icon(Icons.cloud_done_outlined, color: AppColors.good, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    app.syncing ? 'Syncing…' : 'Synced as ${app.syncEmail}',
                    style: const TextStyle(fontSize: 13, color: AppColors.text),
                  ),
                ),
              ],
            ),
            if (app.syncError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(app.syncError!, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
              ),
            const SizedBox(height: 12),
            SecondaryButton(
              onPressed: () => app.disableSync(),
              child: const Text('Turn off sync'),
            ),
          ] else ...[
            TextFormField(
              controller: _emailController,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.text),
              decoration: ironFieldDecoration(hint: 'you@example.com'),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              onPressed: _busy ? null : _sendLink,
              child: Text(_linkSent ? 'Resend sign-in link' : 'Send sign-in link'),
            ),
            if (_linkSent) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                enabled: !_busy,
                style: const TextStyle(color: AppColors.text),
                decoration: ironFieldDecoration(hint: 'Paste the link from your email'),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                onPressed: _busy ? null : _finishSignIn,
                child: const Text('Finish sign-in'),
              ),
            ],
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_message!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
          ],
        ],
      ),
    );
  }
}
