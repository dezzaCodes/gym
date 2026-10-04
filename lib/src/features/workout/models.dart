/// A default estimate for how long a single working set takes, including
/// unracking, adjusting weight, and setup — not just the working reps
/// themselves. Used implicitly to estimate overall workout time.
const defaultSetSeconds = 60;

class ExerciseTemplate {
  String id;
  String name;
  int sets;
  int setSeconds;
  int restSeconds;

  ExerciseTemplate({
    required this.id,
    required this.name,
    required this.sets,
    this.setSeconds = defaultSetSeconds,
    required this.restSeconds,
  });

  ExerciseTemplate copy() =>
      ExerciseTemplate(id: id, name: name, sets: sets, setSeconds: setSeconds, restSeconds: restSeconds);

  factory ExerciseTemplate.fromJson(Map<String, dynamic> json) => ExerciseTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        sets: json['sets'] as int,
        setSeconds: json['setSeconds'] as int? ?? defaultSetSeconds,
        restSeconds: json['restSeconds'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets,
        'setSeconds': setSeconds,
        'restSeconds': restSeconds,
      };
}

class WorkoutTemplate {
  String id;
  String name;
  int targetMinutes;
  List<ExerciseTemplate> exercises;
  // True for a randomly generated workout that hasn't been explicitly saved
  // to the user's workout list yet; such templates are hidden from the
  // Workouts screen until saved.
  bool isTemporary;
  // True when this workout was generated with the "no weights (bodyweight
  // only)" option — kept so exercise swaps mid-workout stay bodyweight-only
  // too, instead of offering a swap that needs equipment.
  bool bodyweightOnly;
  // True when generated with "Weights only" — swaps mid-workout stay
  // restricted to exercises that need equipment too, instead of offering a
  // bodyweight-only swap.
  bool weightsOnly;
  // True when generated with "Favorites only" — swaps mid-workout stay
  // restricted to favorited exercises too.
  bool favoritesOnly;
  // True when generated with "Not done in a while" — swaps mid-workout
  // stay restricted to exercises that are still stale, too.
  bool staleOnly;

  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.targetMinutes,
    required this.exercises,
    this.isTemporary = false,
    this.bodyweightOnly = false,
    this.weightsOnly = false,
    this.favoritesOnly = false,
    this.staleOnly = false,
  });

  WorkoutTemplate copy() => WorkoutTemplate(
        id: id,
        name: name,
        targetMinutes: targetMinutes,
        exercises: exercises.map((e) => e.copy()).toList(),
        isTemporary: isTemporary,
        bodyweightOnly: bodyweightOnly,
        weightsOnly: weightsOnly,
        favoritesOnly: favoritesOnly,
        staleOnly: staleOnly,
      );

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) => WorkoutTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        targetMinutes: json['targetMinutes'] as int,
        exercises: (json['exercises'] as List)
            .map((e) => ExerciseTemplate.fromJson(e as Map<String, dynamic>))
            .toList(),
        isTemporary: json['isTemporary'] as bool? ?? false,
        bodyweightOnly: json['bodyweightOnly'] as bool? ?? false,
        weightsOnly: json['weightsOnly'] as bool? ?? false,
        favoritesOnly: json['favoritesOnly'] as bool? ?? false,
        staleOnly: json['staleOnly'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetMinutes': targetMinutes,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'isTemporary': isTemporary,
        'bodyweightOnly': bodyweightOnly,
        'weightsOnly': weightsOnly,
        'favoritesOnly': favoritesOnly,
        'staleOnly': staleOnly,
      };

  static List<WorkoutTemplate> samples() => [
        WorkoutTemplate(id: 'push', name: 'Push Day', targetMinutes: 45, exercises: [
          ExerciseTemplate(id: 'e1', name: 'Bench Press', sets: 4, setSeconds: 60, restSeconds: 105),
          ExerciseTemplate(id: 'e2', name: 'Overhead Press', sets: 3, setSeconds: 55, restSeconds: 90),
          ExerciseTemplate(id: 'e3', name: 'Incline Dumbbell Press', sets: 3, setSeconds: 55, restSeconds: 90),
          ExerciseTemplate(id: 'e4', name: 'Tricep Pushdown', sets: 3, setSeconds: 40, restSeconds: 75),
        ]),
        WorkoutTemplate(id: 'pull', name: 'Pull Day', targetMinutes: 45, exercises: [
          ExerciseTemplate(id: 'e1', name: 'Deadlift', sets: 4, setSeconds: 70, restSeconds: 135),
          ExerciseTemplate(id: 'e2', name: 'Pull-Up', sets: 4, setSeconds: 45, restSeconds: 105),
          ExerciseTemplate(id: 'e3', name: 'Barbell Row', sets: 3, setSeconds: 55, restSeconds: 105),
          ExerciseTemplate(id: 'e4', name: 'Bicep Curl', sets: 3, setSeconds: 40, restSeconds: 75),
        ]),
        WorkoutTemplate(id: 'legs', name: 'Leg Day', targetMinutes: 50, exercises: [
          ExerciseTemplate(id: 'e1', name: 'Back Squat', sets: 4, setSeconds: 70, restSeconds: 135),
          ExerciseTemplate(id: 'e2', name: 'Romanian Deadlift', sets: 3, setSeconds: 60, restSeconds: 105),
          ExerciseTemplate(id: 'e3', name: 'Walking Lunge', sets: 3, setSeconds: 50, restSeconds: 90),
          ExerciseTemplate(id: 'e4', name: 'Calf Raise', sets: 3, setSeconds: 40, restSeconds: 75),
        ]),
      ];
}

/// A flat 5-minute buffer added per exercise for walking to different
/// equipment, adjusting machines, and other overhead that a pure set/rest
/// sum misses.
const exerciseBufferSeconds = 5 * 60;

/// Estimates how long a workout will take: for each exercise, the sum of its
/// sets' expected working time plus rest, plus a flat 5-minute buffer; those
/// are summed across all exercises, then rounded UP to the nearest 15
/// minutes — always erring generous rather than underselling how long the
/// workout will actually take.
///
/// The final rest of the workout is excluded, since nothing follows it.
int estimateTargetMinutes(WorkoutTemplate template) {
  if (template.exercises.isEmpty) return 30;

  var totalSeconds = 0;
  for (final exercise in template.exercises) {
    totalSeconds += exercise.sets * (exercise.setSeconds + exercise.restSeconds);
    totalSeconds += exerciseBufferSeconds;
  }
  totalSeconds -= template.exercises.last.restSeconds;

  final roundedMinutes = (totalSeconds / 60 / 15).ceil() * 15;
  return roundedMinutes < 15 ? 15 : roundedMinutes;
}

class SetEntry {
  int setNumber;
  double? weight;
  int? reps;
  int? setSeconds;
  int? restSeconds;

  SetEntry({
    required this.setNumber,
    this.weight,
    this.reps,
    this.setSeconds,
    this.restSeconds,
  });

  factory SetEntry.fromJson(Map<String, dynamic> json) => SetEntry(
        setNumber: json['setNumber'] as int,
        weight: (json['weight'] as num?)?.toDouble(),
        reps: json['reps'] as int?,
        setSeconds: json['setSeconds'] as int?,
        restSeconds: json['restSeconds'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'setSeconds': setSeconds,
        'restSeconds': restSeconds,
      };
}

class ExerciseHistoryInstance {
  String date; // yyyy-MM-dd
  int? durationSeconds;
  List<SetEntry> sets;

  ExerciseHistoryInstance({required this.date, this.durationSeconds, required this.sets});

  factory ExerciseHistoryInstance.fromJson(Map<String, dynamic> json) => ExerciseHistoryInstance(
        date: json['date'] as String,
        durationSeconds: json['durationSeconds'] as int?,
        sets: (json['sets'] as List).map((e) => SetEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'durationSeconds': durationSeconds,
        'sets': sets.map((e) => e.toJson()).toList(),
      };
}

class SessionHistoryEntry {
  String date;
  String templateName;
  int durationSeconds;
  int targetSeconds;
  int xpEarned;
  bool onPace;
  // Nullable for entries persisted before this field existed.
  String? templateId;

  SessionHistoryEntry({
    required this.date,
    required this.templateName,
    required this.durationSeconds,
    required this.targetSeconds,
    required this.xpEarned,
    required this.onPace,
    this.templateId,
  });

  factory SessionHistoryEntry.fromJson(Map<String, dynamic> json) => SessionHistoryEntry(
        date: json['date'] as String,
        templateName: json['templateName'] as String,
        durationSeconds: json['durationSeconds'] as int,
        targetSeconds: json['targetSeconds'] as int,
        xpEarned: json['xpEarned'] as int,
        onPace: json['onPace'] as bool,
        templateId: json['templateId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'templateName': templateName,
        'durationSeconds': durationSeconds,
        'targetSeconds': targetSeconds,
        'xpEarned': xpEarned,
        'onPace': onPace,
        'templateId': templateId,
      };
}

class Profile {
  int totalXp;
  int streak;
  String? lastCompletedDate;
  List<String> badges;
  int onPaceCount;
  int sessionCount;

  Profile({
    this.totalXp = 0,
    this.streak = 0,
    this.lastCompletedDate,
    List<String>? badges,
    this.onPaceCount = 0,
    this.sessionCount = 0,
  }) : badges = badges ?? [];

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        totalXp: json['totalXp'] as int? ?? 0,
        streak: json['streak'] as int? ?? 0,
        lastCompletedDate: json['lastCompletedDate'] as String?,
        badges: (json['badges'] as List?)?.map((e) => e as String).toList() ?? [],
        onPaceCount: json['onPaceCount'] as int? ?? 0,
        sessionCount: json['sessionCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'streak': streak,
        'lastCompletedDate': lastCompletedDate,
        'badges': badges,
        'onPaceCount': onPaceCount,
        'sessionCount': sessionCount,
      };
}

class AppData {
  Profile profile;
  List<WorkoutTemplate> templates;
  String activeTemplateId;
  List<SessionHistoryEntry> history;
  Map<String, List<ExerciseHistoryInstance>> exerciseHistory;

  /// Exercise names excluded from random workout generation and exercise
  /// swaps, e.g. because the user doesn't have the equipment for them.
  Set<String> excludedExercises;

  /// Exercise names the user has marked as favorites — browsable from the
  /// exercise glossary, and selectable as a random workout filter.
  Set<String> favoriteExercises;

  AppData({
    Profile? profile,
    List<WorkoutTemplate>? templates,
    this.activeTemplateId = 'push',
    List<SessionHistoryEntry>? history,
    Map<String, List<ExerciseHistoryInstance>>? exerciseHistory,
    Set<String>? excludedExercises,
    Set<String>? favoriteExercises,
  })  : profile = profile ?? Profile(),
        templates = templates ?? WorkoutTemplate.samples(),
        history = history ?? [],
        exerciseHistory = exerciseHistory ?? {},
        excludedExercises = excludedExercises ?? {},
        favoriteExercises = favoriteExercises ?? {};

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
        profile: json['profile'] != null ? Profile.fromJson(json['profile']) : Profile(),
        templates: json['templates'] != null
            ? (json['templates'] as List).map((e) => WorkoutTemplate.fromJson(e)).toList()
            : WorkoutTemplate.samples(),
        activeTemplateId: json['activeTemplateId'] as String? ?? 'push',
        history: json['history'] != null ? (json['history'] as List).map((e) => SessionHistoryEntry.fromJson(e)).toList() : [],
        exerciseHistory: json['exerciseHistory'] != null
            ? (json['exerciseHistory'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, (value as List).map((e) => ExerciseHistoryInstance.fromJson(e)).toList()),
              )
            : {},
        excludedExercises: json['excludedExercises'] != null
            ? (json['excludedExercises'] as List).map((e) => e as String).toSet()
            : {},
        favoriteExercises: json['favoriteExercises'] != null
            ? (json['favoriteExercises'] as List).map((e) => e as String).toSet()
            : {},
      );

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'templates': templates.map((e) => e.toJson()).toList(),
        'activeTemplateId': activeTemplateId,
        'history': history.map((e) => e.toJson()).toList(),
        'exerciseHistory': exerciseHistory.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
        'excludedExercises': excludedExercises.toList(),
        'favoriteExercises': favoriteExercises.toList(),
      };
}

String formatNumber(double n) {
  if (n == n.roundToDouble()) return n.toStringAsFixed(0);
  return n.toString();
}

String formatDuration(int totalSeconds) {
  final sign = totalSeconds < 0 ? '-' : '';
  final s = totalSeconds.abs();
  final m = s ~/ 60;
  final sec = s % 60;
  return '$sign$m:${sec.toString().padLeft(2, '0')}';
}

String formatSetLog(SetEntry s) {
  final parts = <String>[];
  if (s.weight != null) parts.add(formatNumber(s.weight!));
  if (s.reps != null) parts.add('× ${s.reps}');
  return parts.isEmpty ? '—' : parts.join(' ');
}
