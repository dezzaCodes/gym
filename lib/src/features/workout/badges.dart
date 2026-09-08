import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';

/// One achievement badge: its identity, how it's displayed, and the
/// condition that unlocks it.
///
/// [metaThreshold], when set, marks this as a "collector" badge that
/// unlocks based on how many *other* badges have been earned rather than a
/// workout stat — [isEarned] is unused for these ([evaluateBadges] handles
/// them separately to avoid a badge counting itself).
class WorkoutBadge {
  final String id;
  final String title;
  final IconData icon;
  final String category;
  final bool Function(BadgeStats stats) isEarned;
  final int? metaThreshold;

  const WorkoutBadge({
    required this.id,
    required this.title,
    required this.icon,
    required this.category,
    required this.isEarned,
    this.metaThreshold,
  });
}

/// Every stat badges are evaluated against, derived purely from persisted
/// [AppData]. Badge state is always recomputed fresh from this rather than
/// tracked incrementally, so it stays correct no matter how it was reached.
class BadgeStats {
  final int sessionCount;
  final int streak;
  final int totalXp;
  final int onPaceCount;
  final int distinctExerciseCount;
  final double maxWeightEver;
  final int totalSetsEver;
  final int maxSetReps;
  final Set<int> weekdaysTrained;
  final int distinctTemplateCount;
  final int uniqueDaysTrained;
  final int prCount;
  final double bestPaceRatio;
  final int longestOnPaceStreak;
  final bool hadComeback14;
  final bool hadComeback30;
  final int fastestSessionSeconds;
  final int longestSessionSeconds;

  const BadgeStats({
    required this.sessionCount,
    required this.streak,
    required this.totalXp,
    required this.onPaceCount,
    required this.distinctExerciseCount,
    required this.maxWeightEver,
    required this.totalSetsEver,
    required this.maxSetReps,
    required this.weekdaysTrained,
    required this.distinctTemplateCount,
    required this.uniqueDaysTrained,
    required this.prCount,
    required this.bestPaceRatio,
    required this.longestOnPaceStreak,
    required this.hadComeback14,
    required this.hadComeback30,
    required this.fastestSessionSeconds,
    required this.longestSessionSeconds,
  });
}

BadgeStats computeBadgeStats(AppData data) {
  final profile = data.profile;

  var maxWeightEver = 0.0;
  var totalSetsEver = 0;
  var maxSetReps = 0;
  var prCount = 0;

  for (final entry in data.exerciseHistory.entries) {
    final sortedInstances = [...entry.value]..sort((a, b) => a.date.compareTo(b.date));
    double? runningMax;
    for (final inst in sortedInstances) {
      double? instanceMax;
      for (final set in inst.sets) {
        totalSetsEver++;
        if (set.weight != null) {
          maxWeightEver = math.max(maxWeightEver, set.weight!);
          instanceMax = instanceMax == null ? set.weight! : math.max(instanceMax, set.weight!);
        }
        if (set.reps != null) {
          maxSetReps = math.max(maxSetReps, set.reps!);
        }
      }
      // A new personal record is a session where this exercise's heaviest
      // set beat every prior session's heaviest set for it.
      if (instanceMax != null) {
        if (runningMax != null && instanceMax > runningMax) {
          prCount++;
        }
        runningMax = runningMax == null ? instanceMax : math.max(runningMax, instanceMax);
      }
    }
  }

  final weekdaysTrained = <int>{};
  final uniqueDates = <String>{};
  final templateNames = <String>{};
  var bestPaceRatio = 1.0;
  var fastestSessionSeconds = 0;
  var longestSessionSeconds = 0;
  var longestOnPaceStreak = 0;
  var currentOnPaceRun = 0;
  var hadComeback14 = false;
  var hadComeback30 = false;
  var isFirstEntry = true;

  final sortedHistory = [...data.history]..sort((a, b) => a.date.compareTo(b.date));
  DateTime? previousDate;
  for (final entry in sortedHistory) {
    uniqueDates.add(entry.date);
    templateNames.add(entry.templateName);

    final parsed = DateTime.tryParse(entry.date);
    if (parsed != null) {
      weekdaysTrained.add(parsed.weekday);
      if (previousDate != null) {
        final gap = parsed.difference(previousDate).inDays;
        if (gap >= 30) hadComeback30 = true;
        if (gap >= 14) hadComeback14 = true;
      }
      previousDate = parsed;
    }

    if (entry.targetSeconds > 0) {
      final ratio = entry.durationSeconds / entry.targetSeconds;
      if (ratio < bestPaceRatio) bestPaceRatio = ratio;
    }

    if (isFirstEntry) {
      fastestSessionSeconds = entry.durationSeconds;
      isFirstEntry = false;
    } else {
      fastestSessionSeconds = math.min(fastestSessionSeconds, entry.durationSeconds);
    }
    longestSessionSeconds = math.max(longestSessionSeconds, entry.durationSeconds);

    if (entry.onPace) {
      currentOnPaceRun++;
      longestOnPaceStreak = math.max(longestOnPaceStreak, currentOnPaceRun);
    } else {
      currentOnPaceRun = 0;
    }
  }

  return BadgeStats(
    sessionCount: profile.sessionCount,
    streak: profile.streak,
    totalXp: profile.totalXp,
    onPaceCount: profile.onPaceCount,
    distinctExerciseCount: data.exerciseHistory.keys.length,
    maxWeightEver: maxWeightEver,
    totalSetsEver: totalSetsEver,
    maxSetReps: maxSetReps,
    weekdaysTrained: weekdaysTrained,
    distinctTemplateCount: templateNames.length,
    uniqueDaysTrained: uniqueDates.length,
    prCount: prCount,
    bestPaceRatio: bestPaceRatio,
    longestOnPaceStreak: longestOnPaceStreak,
    hadComeback14: hadComeback14,
    hadComeback30: hadComeback30,
    fastestSessionSeconds: fastestSessionSeconds,
    longestSessionSeconds: longestSessionSeconds,
  );
}

List<WorkoutBadge> _thresholdBadges({
  required String idPrefix,
  required IconData icon,
  required String category,
  required List<num> thresholds,
  required List<String> titles,
  required num Function(BadgeStats) valueOf,
}) {
  assert(thresholds.length == titles.length);
  return [
    for (var i = 0; i < thresholds.length; i++)
      WorkoutBadge(
        id: '${idPrefix}_${thresholds[i]}',
        title: titles[i],
        icon: icon,
        category: category,
        isEarned: (stats) => valueOf(stats) >= thresholds[i],
      ),
  ];
}

const _weekdayIds = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
const _weekdayTitles = [
  'Monday Mover',
  'Tuesday Trainer',
  'Wednesday Warrior',
  'Thursday Thrasher',
  'Friday Finisher',
  'Saturday Sweat',
  'Sunday Session',
];

/// The full set of 100 badges, grouped into 17 categories spanning easy
/// first-timer milestones through long-haul, hard-to-reach ones.
class BadgeCatalog {
  static final List<WorkoutBadge> _sessions = _thresholdBadges(
    idPrefix: 'sessions',
    icon: Icons.event_available,
    category: 'Sessions',
    thresholds: const [1, 5, 10, 25, 50, 75, 100, 200, 500, 1000],
    titles: const [
      'First Rep',
      'Getting Started',
      'Iron Regular',
      'Quarter Century',
      'Half Century',
      'Iron Committed',
      'Centurion',
      'Double Century',
      'Iron Veteran',
      'Iron Legend',
    ],
    valueOf: (s) => s.sessionCount,
  );

  static final List<WorkoutBadge> _streaks = _thresholdBadges(
    idPrefix: 'streak',
    icon: Icons.local_fire_department,
    category: 'Streaks',
    thresholds: const [3, 7, 14, 30, 60, 100, 200, 365],
    titles: const [
      'Warming Up',
      'Locked In',
      'Two Weeks Strong',
      'Iron Habit',
      'Unstoppable',
      'Streak Master',
      'Relentless',
      'Iron Year',
    ],
    valueOf: (s) => s.streak,
  );

  static final List<WorkoutBadge> _xp = _thresholdBadges(
    idPrefix: 'xp',
    icon: Icons.bolt,
    category: 'Experience',
    thresholds: const [100, 500, 1000, 2500, 5000, 10000, 25000, 50000],
    titles: const [
      'First XP',
      'Rising',
      'Iron Novice',
      'Iron Apprentice',
      'Iron Adept',
      'Iron Expert',
      'Iron Master',
      'Iron Grandmaster',
    ],
    valueOf: (s) => s.totalXp,
  );

  static final List<WorkoutBadge> _onPace = _thresholdBadges(
    idPrefix: 'onpace',
    icon: Icons.verified,
    category: 'On Pace',
    thresholds: const [1, 5, 10, 25, 50, 100, 150],
    titles: const ['On the Clock', 'Punctual', 'Timekeeper', 'Pace Setter', 'Metronome', 'Chronomaster', 'Time Lord'],
    valueOf: (s) => s.onPaceCount,
  );

  static final List<WorkoutBadge> _speed = [
    for (final tier in const [
      (ratio: 0.9, title: 'Quick Finish'),
      (ratio: 0.8, title: 'Speed Demon'),
      (ratio: 0.7, title: 'Fast Lane'),
      (ratio: 0.6, title: 'Lightning'),
      (ratio: 0.5, title: 'Sonic'),
    ])
      WorkoutBadge(
        id: 'speed_${(tier.ratio * 100).round()}',
        title: tier.title,
        icon: Icons.speed,
        category: 'Speed',
        isEarned: (stats) => stats.bestPaceRatio <= tier.ratio,
      ),
  ];

  static final List<WorkoutBadge> _variety = _thresholdBadges(
    idPrefix: 'variety',
    icon: Icons.category,
    category: 'Exercise Variety',
    thresholds: const [3, 5, 10, 15, 25, 35, 50],
    titles: const ['Trying Things', 'Well Rounded', 'Explorer', 'Versatile', 'Renaissance Lifter', 'Encyclopedia', 'Master of All'],
    valueOf: (s) => s.distinctExerciseCount,
  );

  static final List<WorkoutBadge> _strength = _thresholdBadges(
    idPrefix: 'strength',
    icon: Icons.fitness_center,
    category: 'Strength',
    thresholds: const [25, 50, 100, 135, 185, 225, 315],
    titles: const ['First Plates', 'Getting Heavy', 'Triple Digits', 'One Plate', 'Getting Serious', 'Two Plates', 'Three Plates'],
    valueOf: (s) => s.maxWeightEver,
  );

  static final List<WorkoutBadge> _volume = _thresholdBadges(
    idPrefix: 'volume',
    icon: Icons.stacked_bar_chart,
    category: 'Volume',
    thresholds: const [25, 50, 100, 500, 1000, 2500, 5000, 10000],
    titles: const [
      'Set In Motion',
      'Half Century Sets',
      'Century Sets',
      'High Volume',
      'Set Machine',
      'Volume King',
      'Set Legend',
      'Ten Thousand Sets',
    ],
    valueOf: (s) => s.totalSetsEver,
  );

  static final List<WorkoutBadge> _reps = _thresholdBadges(
    idPrefix: 'reps',
    icon: Icons.repeat,
    category: 'Reps',
    thresholds: const [10, 15, 20, 30, 50, 100],
    titles: const ['Double Digits', 'Rep Range', 'High Reps', 'Endurance', 'Rep Machine', 'Century Reps'],
    valueOf: (s) => s.maxSetReps,
  );

  static final List<WorkoutBadge> _templates = _thresholdBadges(
    idPrefix: 'templates',
    icon: Icons.dashboard_customize_outlined,
    category: 'Program Variety',
    thresholds: const [1, 2, 3, 5],
    titles: const ['First Plan', 'Mixing It Up', 'Well Balanced', 'Program Collector'],
    valueOf: (s) => s.distinctTemplateCount,
  );

  static final List<WorkoutBadge> _weekdays = [
    for (var i = 0; i < _weekdayIds.length; i++)
      WorkoutBadge(
        id: 'weekday_${_weekdayIds[i]}',
        title: _weekdayTitles[i],
        icon: Icons.calendar_today,
        category: 'Weekly Coverage',
        isEarned: (stats) => stats.weekdaysTrained.contains(i + 1),
      ),
  ];

  static final List<WorkoutBadge> _days = _thresholdBadges(
    idPrefix: 'days',
    icon: Icons.date_range,
    category: 'Days Trained',
    thresholds: const [5, 10, 25, 50, 100, 365],
    titles: const ['Five Days In', 'Ten Days Strong', 'Quarter Century Days', 'Half Century Days', 'Century of Days', 'Full Year'],
    valueOf: (s) => s.uniqueDaysTrained,
  );

  static final List<WorkoutBadge> _prs = _thresholdBadges(
    idPrefix: 'pr',
    icon: Icons.emoji_events,
    category: 'Personal Records',
    thresholds: const [1, 5, 10, 25, 50],
    titles: const ['First PR', 'Record Breaker', 'PR Hunter', 'PR Machine', 'PR Legend'],
    valueOf: (s) => s.prCount,
  );

  static final List<WorkoutBadge> _onPaceStreak = _thresholdBadges(
    idPrefix: 'onpacestreak',
    icon: Icons.timeline,
    category: 'Consistency',
    thresholds: const [3, 5, 10],
    titles: const ['Three in a Row', 'Five Straight', 'Ten Straight'],
    valueOf: (s) => s.longestOnPaceStreak,
  );

  static final List<WorkoutBadge> _comeback = [
    WorkoutBadge(
      id: 'comeback_14',
      title: 'The Comeback',
      icon: Icons.replay,
      category: 'Comebacks',
      isEarned: (stats) => stats.hadComeback14,
    ),
    WorkoutBadge(
      id: 'comeback_30',
      title: 'Phoenix',
      icon: Icons.replay,
      category: 'Comebacks',
      isEarned: (stats) => stats.hadComeback30,
    ),
  ];

  static final List<WorkoutBadge> _duration = [
    WorkoutBadge(
      id: 'duration_efficient',
      title: 'Efficient',
      icon: Icons.timer,
      category: 'Duration',
      isEarned: (stats) => stats.fastestSessionSeconds > 0 && stats.fastestSessionSeconds <= 20 * 60,
    ),
    WorkoutBadge(
      id: 'duration_grinder',
      title: 'Grinder',
      icon: Icons.timer,
      category: 'Duration',
      isEarned: (stats) => stats.longestSessionSeconds >= 60 * 60,
    ),
    WorkoutBadge(
      id: 'duration_marathon',
      title: 'Iron Marathon',
      icon: Icons.timer,
      category: 'Duration',
      isEarned: (stats) => stats.longestSessionSeconds >= 90 * 60,
    ),
  ];

  static final List<WorkoutBadge> _meta = [
    for (final tier in const [
      (threshold: 10, title: 'Badge Collector'),
      (threshold: 25, title: 'Badge Hoarder'),
      (threshold: 50, title: 'Badge Connoisseur'),
      (threshold: 75, title: 'Badge Completionist'),
    ])
      WorkoutBadge(
        id: 'meta_${tier.threshold}',
        title: tier.title,
        icon: Icons.workspace_premium,
        category: 'Collector',
        isEarned: (_) => false,
        metaThreshold: tier.threshold,
      ),
  ];

  static final List<WorkoutBadge> all = [
    ..._sessions,
    ..._streaks,
    ..._xp,
    ..._onPace,
    ..._speed,
    ..._variety,
    ..._strength,
    ..._volume,
    ..._reps,
    ..._templates,
    ..._weekdays,
    ..._days,
    ..._prs,
    ..._onPaceStreak,
    ..._comeback,
    ..._duration,
    ..._meta,
  ];

  static WorkoutBadge? byId(String id) {
    for (final badge in all) {
      if (badge.id == id) return badge;
    }
    return null;
  }
}

class BadgeEvaluation {
  final List<String> allEarnedIds;
  final List<WorkoutBadge> newlyUnlocked;
  const BadgeEvaluation({required this.allEarnedIds, required this.newlyUnlocked});
}

/// Recomputes the full badge set from scratch against [data]. Badges are
/// never revoked once earned — this only ever adds to what's already
/// stored, even if a stat later regresses (e.g. a broken streak).
BadgeEvaluation evaluateBadges(AppData data) {
  final stats = computeBadgeStats(data);
  final existing = Set<String>.from(data.profile.badges);
  final earned = Set<String>.from(existing);

  for (final badge in BadgeCatalog.all) {
    if (badge.metaThreshold != null) continue;
    if (badge.isEarned(stats)) earned.add(badge.id);
  }

  final nonMetaEarnedCount = earned.where((id) => BadgeCatalog.byId(id)?.metaThreshold == null).length;
  for (final badge in BadgeCatalog.all) {
    final threshold = badge.metaThreshold;
    if (threshold != null && nonMetaEarnedCount >= threshold) {
      earned.add(badge.id);
    }
  }

  final newlyUnlocked = earned.difference(existing).map((id) => BadgeCatalog.byId(id)).whereType<WorkoutBadge>().toList();

  return BadgeEvaluation(allEarnedIds: earned.toList(), newlyUnlocked: newlyUnlocked);
}
