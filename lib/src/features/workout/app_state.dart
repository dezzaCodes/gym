import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_workout_repository.dart';
import '../../services/rest_notification_service.dart';
import 'badges.dart';
import 'exercise_library.dart';
import 'models.dart';
import 'random_workout.dart';
import 'storage.dart';

enum Screen { home, workouts, edit, active, summary, progress, stats, badges, exercises, exerciseDetail, sessionDetail }

enum SessionPhase { working, resting }

class SetLogEntry {
  String exerciseName;
  int setNumber;
  double? weight;
  int? reps;
  int? setSeconds;
  int? restSeconds;

  SetLogEntry({
    required this.exerciseName,
    required this.setNumber,
    this.weight,
    this.reps,
    this.setSeconds,
    this.restSeconds,
  });

  factory SetLogEntry.fromJson(Map<String, dynamic> json) => SetLogEntry(
        exerciseName: json['exerciseName'] as String,
        setNumber: json['setNumber'] as int,
        weight: (json['weight'] as num?)?.toDouble(),
        reps: json['reps'] as int?,
        setSeconds: json['setSeconds'] as int?,
        restSeconds: json['restSeconds'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'exerciseName': exerciseName,
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'setSeconds': setSeconds,
        'restSeconds': restSeconds,
      };
}

class WorkoutSession {
  String templateId;
  int elapsed;
  int exIndex;
  int setIndex;
  SessionPhase phase;
  int restElapsed;
  bool paused;
  int completedSets;
  String currentWeight;
  String currentReps;
  List<SetLogEntry> logs;
  List<CompletedExercise> completedExercises;
  int exerciseStartElapsed;
  int exerciseStartExIndex;
  int setStartElapsed;
  int pendingRestSeconds;

  /// Exercises swapped in for this session only (e.g. no equipment for the
  /// original pick), keyed by exercise index. The saved template is left
  /// untouched.
  Map<int, ExerciseTemplate> exerciseOverrides;

  /// When this session was last saved to disk, so a restored session can
  /// account for real time that passed while the app was closed (adding it
  /// to [elapsed]/[restElapsed]) instead of resuming as if no time had
  /// passed.
  DateTime lastActiveAt;

  WorkoutSession({
    required this.templateId,
    this.elapsed = 0,
    this.exIndex = 0,
    this.setIndex = 1,
    this.phase = SessionPhase.working,
    this.restElapsed = 0,
    this.paused = false,
    this.completedSets = 0,
    this.currentWeight = '',
    this.currentReps = '',
    List<SetLogEntry>? logs,
    List<CompletedExercise>? completedExercises,
    this.exerciseStartElapsed = 0,
    this.exerciseStartExIndex = 0,
    this.setStartElapsed = 0,
    this.pendingRestSeconds = 0,
    Map<int, ExerciseTemplate>? exerciseOverrides,
    DateTime? lastActiveAt,
  })  : logs = logs ?? [],
        completedExercises = completedExercises ?? [],
        exerciseOverrides = exerciseOverrides ?? {},
        lastActiveAt = lastActiveAt ?? DateTime.now();

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        templateId: json['templateId'] as String,
        elapsed: json['elapsed'] as int? ?? 0,
        exIndex: json['exIndex'] as int? ?? 0,
        setIndex: json['setIndex'] as int? ?? 1,
        phase: json['phase'] == 'resting' ? SessionPhase.resting : SessionPhase.working,
        restElapsed: json['restElapsed'] as int? ?? 0,
        paused: json['paused'] as bool? ?? false,
        completedSets: json['completedSets'] as int? ?? 0,
        currentWeight: json['currentWeight'] as String? ?? '',
        currentReps: json['currentReps'] as String? ?? '',
        logs: json['logs'] != null
            ? (json['logs'] as List).map((e) => SetLogEntry.fromJson(e as Map<String, dynamic>)).toList()
            : [],
        completedExercises: json['completedExercises'] != null
            ? (json['completedExercises'] as List)
                .map((e) => CompletedExercise.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
        exerciseStartElapsed: json['exerciseStartElapsed'] as int? ?? 0,
        exerciseStartExIndex: json['exerciseStartExIndex'] as int? ?? 0,
        setStartElapsed: json['setStartElapsed'] as int? ?? 0,
        pendingRestSeconds: json['pendingRestSeconds'] as int? ?? 0,
        exerciseOverrides: json['exerciseOverrides'] != null
            ? (json['exerciseOverrides'] as Map<String, dynamic>)
                .map((k, v) => MapEntry(int.parse(k), ExerciseTemplate.fromJson(v as Map<String, dynamic>)))
            : {},
        lastActiveAt: json['lastActiveAt'] != null ? DateTime.parse(json['lastActiveAt'] as String) : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'elapsed': elapsed,
        'exIndex': exIndex,
        'setIndex': setIndex,
        'phase': phase == SessionPhase.resting ? 'resting' : 'working',
        'restElapsed': restElapsed,
        'paused': paused,
        'completedSets': completedSets,
        'currentWeight': currentWeight,
        'currentReps': currentReps,
        'logs': logs.map((e) => e.toJson()).toList(),
        'completedExercises': completedExercises.map((e) => e.toJson()).toList(),
        'exerciseStartElapsed': exerciseStartElapsed,
        'exerciseStartExIndex': exerciseStartExIndex,
        'setStartElapsed': setStartElapsed,
        'pendingRestSeconds': pendingRestSeconds,
        'exerciseOverrides': exerciseOverrides.map((k, v) => MapEntry(k.toString(), v.toJson())),
        'lastActiveAt': lastActiveAt.toIso8601String(),
      };
}

class WorkoutSummary {
  String templateId;
  int durationSeconds;
  int targetSeconds;
  bool onPace;
  int xpEarned;
  int baseXp;
  int speedBonus;
  int streakBonus;
  int streak;
  List<WorkoutBadge> unlockedNow;
  List<CompletedExercise> completedExercises;

  WorkoutSummary({
    required this.templateId,
    required this.durationSeconds,
    required this.targetSeconds,
    required this.onPace,
    required this.xpEarned,
    required this.baseXp,
    required this.speedBonus,
    required this.streakBonus,
    required this.streak,
    required this.unlockedNow,
    required this.completedExercises,
  });
}

class WorkoutAppState extends ChangeNotifier with WidgetsBindingObserver {
  WorkoutAppState({AuthService? authService, CloudWorkoutRepository? cloudRepository})
      : _auth = authService,
        _cloud = cloudRepository {
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  AppData data = AppData();
  Screen screen = Screen.home;
  WorkoutSession? session;
  WorkoutSummary? summary;
  String? editingTemplateId;
  Screen editReturn = Screen.workouts;
  String? selectedExerciseName;
  int? selectedSessionIndex;
  bool loaded = false;

  final AuthService? _auth;
  final CloudWorkoutRepository? _cloud;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<Map<String, dynamic>?>? _cloudSubscription;
  bool _syncing = false;
  String? _syncError;

  final RestNotificationService _restNotifications = RestNotificationService();

  Timer? _timer;
  DateTime? _lastTick;

  // A counter appended to generated ids so two calls landing in the same
  // millisecond (e.g. rapid double-taps) still get distinct ids, rather
  // than one silently shadowing the other in lookups like [templateById].
  int _idSeq = 0;
  String _newId(String prefix) => '$prefix${DateTime.now().millisecondsSinceEpoch}_${_idSeq++}';

  /// Whether this build has cloud sync wired up at all (i.e. Firebase is
  /// configured). When false, the sync UI should not be shown.
  bool get syncAvailable => _auth != null && _cloud != null;
  bool get signedIn => _auth?.currentUser != null;
  String? get syncEmail => _auth?.currentUser?.email;
  bool get syncing => _syncing;
  String? get syncError => _syncError;

  Future<void> _load() async {
    data = await Storage.load();

    final sessionJson = await Storage.loadSession();
    if (sessionJson != null) {
      try {
        final restored = WorkoutSession.fromJson(sessionJson);
        // Account for real time that passed while the app was closed, so
        // the workout doesn't resume as if no time had elapsed.
        _reconcileElapsedGap(restored);
        session = restored;
        screen = Screen.active;
        _startTimer();
        _rescheduleRestNotification();
      } catch (e) {
        await Storage.saveSession(null);
      }
    }

    loaded = true;
    notifyListeners();
    _authSubscription = _auth?.authStateChanges.listen(_handleAuthChanged);
    unawaited(_restNotifications.initialize());
  }

  /// Saves (or, when there's no active workout, clears) the in-progress
  /// session so it survives the app being closed, the OS killing it in the
  /// background, or the screen turning off.
  Future<void> _persistSession() async {
    final s = session;
    if (s == null) {
      await Storage.saveSession(null);
      return;
    }
    s.lastActiveAt = DateTime.now();
    await Storage.saveSession(s.toJson());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_persistSession());
    } else if (state == AppLifecycleState.resumed) {
      // The OS commonly suspends or throttles timers while backgrounded,
      // so simply letting the periodic timer carry on from where it left
      // off would leave the clock behind by however long the app was away
      // — same gap the cold-start path in `_load` accounts for, just
      // triggered by a resume instead of a fresh launch.
      final s = session;
      if (s != null && _reconcileElapsedGap(s)) {
        unawaited(_persistSession());
        notifyListeners();
      }
    }
  }

  /// Adds whatever real time passed since [s.lastActiveAt] onto its elapsed
  /// counters, so a gap spent backgrounded or fully closed doesn't make the
  /// workout resume as if no time had gone by. Bumps [s.lastActiveAt] (and
  /// [_lastTick], so the periodic timer's own delta-based catch-up in
  /// [_startTimer] doesn't then add the same gap a second time on its next
  /// tick) to now whenever it applies a gap. Returns whether anything
  /// changed.
  bool _reconcileElapsedGap(WorkoutSession s) {
    if (s.paused) return false;
    final gap = DateTime.now().difference(s.lastActiveAt).inSeconds;
    if (gap <= 0) return false;
    s.elapsed += gap;
    if (s.phase == SessionPhase.resting) s.restElapsed += gap;
    s.lastActiveAt = DateTime.now();
    _lastTick = s.lastActiveAt;
    return true;
  }

  Future<void> persist() async {
    notifyListeners();
    await Storage.save(data);

    final uid = _auth?.currentUser?.uid;
    if (uid == null || _cloud == null) return;
    try {
      await _cloud.save(uid, data.toJson());
      _syncError = null;
    } catch (error) {
      _syncError = error.toString();
      notifyListeners();
    }
  }

  Future<void> _handleAuthChanged(User? user) async {
    await _cloudSubscription?.cancel();
    _cloudSubscription = null;

    final cloud = _cloud;
    if (user == null || cloud == null) {
      notifyListeners();
      return;
    }

    _syncing = true;
    notifyListeners();
    try {
      final remote = await cloud.fetch(user.uid);
      if (remote != null) {
        data = AppData.fromJson(remote);
        await Storage.save(data);
      } else {
        await cloud.save(user.uid, data.toJson());
      }
      _syncError = null;
    } catch (error) {
      _syncError = error.toString();
    }
    _syncing = false;
    notifyListeners();

    _cloudSubscription = cloud.watch(user.uid).listen(
      (remote) {
        // Avoid pulling in a remote update mid-workout, where it would
        // disrupt the in-progress session.
        if (remote == null || session != null) return;
        data = AppData.fromJson(remote);
        notifyListeners();
        Storage.save(data);
      },
      onError: (Object error) {
        _syncError = error.toString();
        notifyListeners();
      },
    );
  }

  /// Signs in with Google. Returns an error message, or null on success —
  /// including when the user simply closes the account picker, which isn't
  /// treated as a real error.
  Future<String?> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) return 'Sync is not available in this build.';
    try {
      await auth.signInWithGoogle();
      return null;
    } catch (error) {
      if (error is FirebaseAuthException && error.code == 'popup-closed-by-user') {
        return null;
      }
      return error.toString();
    }
  }

  Future<void> disableSync() async {
    await _cloudSubscription?.cancel();
    _cloudSubscription = null;
    await _auth?.signOut();
  }

  WorkoutTemplate templateById(String id) {
    return data.templates.firstWhere((t) => t.id == id, orElse: () => data.templates.first);
  }

  /// The exercise at [index] for this session, honoring any exercise swapped
  /// in for this session only via [WorkoutSession.exerciseOverrides].
  ExerciseTemplate exerciseAt(WorkoutTemplate tmpl, WorkoutSession session, int index) {
    return session.exerciseOverrides[index] ?? tmpl.exercises[index];
  }

  /// How far through the workout you actually are right now, as a 0–1
  /// fraction of completed sets, weighting each exercise by its own
  /// expected time (sets × (set time + rest)) rather than treating every
  /// set as equal — a heavy 4-set squat block counts for more of the
  /// workout than a quick 3-set accessory move. This is your current pace
  /// through the work, plotted against the time-elapsed fill to show
  /// whether you're ahead or behind.
  double currentPaceFraction() {
    final s = session;
    if (s == null) return 0;
    final tmpl = templateById(s.templateId);
    if (tmpl.exercises.isEmpty) return 0;

    var totalWeight = 0;
    var completedWeight = 0;
    for (var i = 0; i < tmpl.exercises.length; i++) {
      final ex = exerciseAt(tmpl, s, i);
      final weight = ex.sets * (ex.setSeconds + ex.restSeconds);
      totalWeight += weight;
      if (i < s.exIndex) {
        completedWeight += weight;
      } else if (i == s.exIndex) {
        final completedSets = (s.setIndex - 1).clamp(0, ex.sets);
        completedWeight += completedSets * (ex.setSeconds + ex.restSeconds);
      }
    }
    if (totalWeight == 0) return 0;
    return (completedWeight / totalWeight).clamp(0.0, 1.0);
  }

  ({int level, int into, int need}) levelInfo() {
    const need = 250;
    final level = data.profile.totalXp ~/ need + 1;
    final into = data.profile.totalXp % need;
    return (level: level, into: into, need: need);
  }

  // MARK: Navigation (always go through these so the UI rebuilds)

  void goTo(Screen s) {
    screen = s;
    notifyListeners();
  }

  void openEditForTemplate(String templateId, Screen returnTo) {
    editingTemplateId = templateId;
    editReturn = returnTo;
    screen = Screen.edit;
    notifyListeners();
  }

  void openExercises() {
    screen = Screen.exercises;
    notifyListeners();
  }

  void openExerciseDetail(String name) {
    selectedExerciseName = name;
    screen = Screen.exerciseDetail;
    notifyListeners();
  }

  void closeExerciseDetail() {
    selectedExerciseName = null;
    screen = Screen.exercises;
    notifyListeners();
  }

  void openSessionDetail(int index) {
    selectedSessionIndex = index;
    screen = Screen.sessionDetail;
    notifyListeners();
  }

  void closeSessionDetail() {
    selectedSessionIndex = null;
    screen = Screen.stats;
    notifyListeners();
  }

  void selectTemplate(String id) {
    data.activeTemplateId = id;
    screen = Screen.home;
    persist();
  }

  void startTemplateNow(String id) {
    data.activeTemplateId = id;
    startWorkout(templateId: id);
  }

  void newTemplateAndEdit() {
    final id = newTemplate();
    openEditForTemplate(id, Screen.workouts);
  }

  void dismissSummary() {
    summary = null;
    screen = Screen.home;
    notifyListeners();
  }

  // MARK: Timer

  void _startTimer() {
    _timer?.cancel();
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = session;
      final now = DateTime.now();
      // A real elapsed-time delta rather than a flat +1: browsers throttle
      // (or fully suspend) a background tab's timers, so a hidden tab's
      // ticks can arrive minutes apart instead of every second — using the
      // actual gap here catches the clock up on the very next tick instead
      // of depending on a lifecycle "resumed" event, which web doesn't
      // reliably deliver for a tab switch the way mobile does for
      // backgrounding.
      final delta = now.difference(_lastTick!).inSeconds;
      _lastTick = now;
      if (s == null || s.paused || delta <= 0) return;
      s.elapsed += delta;
      if (s.phase == SessionPhase.resting) s.restElapsed += delta;
      // Kept fresh on every tick (not just the throttled disk write below)
      // so that if a lifecycle "resumed" event reconciles the gap before
      // this timer gets a chance to fire its own catch-up tick, it has an
      // accurate, recent baseline to measure from rather than whatever was
      // last written to disk up to 5 seconds ago.
      s.lastActiveAt = now;
      notifyListeners();
      if (s.elapsed % 5 == 0) unawaited(_persistSession());
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _authSubscription?.cancel();
    _cloudSubscription?.cancel();
    super.dispose();
  }

  // MARK: Prefill / progression suggestion

  /// Prefills a set's weight/reps from the same set number's value the last
  /// time this exercise was performed. If it's never been done before,
  /// falls back to whatever was just logged for it earlier in [sessionLogs]
  /// (i.e. the previous set of this exercise this session, or the first set
  /// if this is set 2), so a brand-new exercise still carries values forward
  /// set to set instead of leaving them blank.
  ({String weight, String reps}) prefill(
    String exerciseName,
    int setNumber, {
    List<SetLogEntry>? sessionLogs,
  }) {
    final hist = data.exerciseHistory[exerciseName];
    if (hist != null && hist.isNotEmpty) {
      final last = hist.last;
      SetEntry? match;
      for (final s in last.sets) {
        if (s.setNumber == setNumber) {
          match = s;
          break;
        }
      }
      match ??= last.sets.isNotEmpty ? last.sets.last : null;
      if (match != null) {
        final w = match.weight != null ? formatNumber(match.weight!) : '';
        final r = match.reps != null ? match.reps.toString() : '';
        return (weight: w, reps: r);
      }
    }

    SetLogEntry? priorInSession;
    for (final log in sessionLogs ?? const <SetLogEntry>[]) {
      if (log.exerciseName == exerciseName) priorInSession = log;
    }
    if (priorInSession != null) {
      final w = priorInSession.weight != null ? formatNumber(priorInSession.weight!) : '';
      final r = priorInSession.reps != null ? priorInSession.reps.toString() : '';
      return (weight: w, reps: r);
    }

    return (weight: '', reps: '');
  }

  /// This exercise's saved history, plus a live entry built from whatever
  /// has been logged for it so far in the current session — so its chart
  /// updates immediately as sets are finished, rather than waiting for the
  /// whole workout to end (when the session's sets are actually persisted).
  ///
  /// Appended rather than replacing any existing entry for today: doing the
  /// same exercise a second time today (a separate workout, redone later)
  /// should add another line to the chart, not erase the earlier one.
  List<ExerciseHistoryInstance> exerciseHistoryIncludingToday(String exerciseName) {
    final persisted = data.exerciseHistory[exerciseName] ?? [];
    final s = session;
    if (s == null) return persisted;

    final todaysLogs = s.logs.where((l) => l.exerciseName == exerciseName).toList();
    if (todaysLogs.isEmpty) return persisted;

    final liveInstance = ExerciseHistoryInstance(
      date: _todayString(),
      sets: todaysLogs
          .map((l) => SetEntry(
                setNumber: l.setNumber,
                weight: l.weight,
                reps: l.reps,
                setSeconds: l.setSeconds,
                restSeconds: l.restSeconds,
              ))
          .toList(),
    );

    return [...persisted, liveInstance];
  }

  /// Compares a specific set (by set number) to the same set number from
  /// the previous session for this exercise — set 1 vs last time's set 1,
  /// set 2 vs set 2, and so on.
  String? progressionSuggestion(String exerciseName, int setNumber) {
    final hist = data.exerciseHistory[exerciseName];
    if (hist == null || hist.length < 2) return null;
    final last = hist[hist.length - 1];
    final prev = hist[hist.length - 2];

    SetEntry? lastSet;
    for (final s in last.sets) {
      if (s.setNumber == setNumber) {
        lastSet = s;
        break;
      }
    }
    SetEntry? prevSet;
    for (final s in prev.sets) {
      if (s.setNumber == setNumber) {
        prevSet = s;
        break;
      }
    }
    if (lastSet == null || prevSet == null) return null;
    if (lastSet.weight == null || prevSet.weight == null) return null;
    if (lastSet.weight != prevSet.weight) return null;
    if (lastSet.reps == null || lastSet.reps! < 8) return null;

    return 'Set $setNumber was ${formatNumber(lastSet.weight!)} × ${lastSet.reps} the last two times. '
        'Might be time to add weight to this set.';
  }

  // MARK: Workout flow

  void startWorkout({String? templateId}) {
    final id = templateId ?? data.activeTemplateId;
    final tmpl = templateById(id);
    if (tmpl.exercises.isEmpty) return;
    final firstEx = tmpl.exercises.first;
    final pre = prefill(firstEx.name, 1);
    session = WorkoutSession(templateId: id, currentWeight: pre.weight, currentReps: pre.reps);
    screen = Screen.active;
    _startTimer();
    unawaited(_restNotifications.cancelRestComplete());
    unawaited(_persistSession());
    notifyListeners();
  }

  void updateCurrentWeight(String v) {
    final s = session;
    if (s == null) return;
    s.currentWeight = v;
    notifyListeners();
  }

  void updateCurrentReps(String v) {
    final s = session;
    if (s == null) return;
    s.currentReps = v;
    notifyListeners();
  }

  void completeSet() {
    final s = session;
    if (s == null) return;
    final tmpl = templateById(s.templateId);
    final ex = exerciseAt(tmpl, s, s.exIndex);

    final weightNum = double.tryParse(s.currentWeight);
    final repsNum = int.tryParse(s.currentReps);
    final actualSetSeconds = s.elapsed - s.setStartElapsed;
    final actualRestSeconds = s.pendingRestSeconds > 0 ? s.pendingRestSeconds : null;
    s.logs.add(SetLogEntry(
      exerciseName: ex.name,
      setNumber: s.setIndex,
      weight: weightNum,
      reps: repsNum,
      setSeconds: actualSetSeconds,
      restSeconds: actualRestSeconds,
    ));
    s.pendingRestSeconds = 0;

    final isLastSetOfExercise = s.setIndex >= ex.sets;
    final isLastExercise = s.exIndex >= tmpl.exercises.length - 1;

    if (isLastSetOfExercise) {
      final duration = s.elapsed - s.exerciseStartElapsed;
      final setsForExercise = s.logs
          .where((l) => l.exerciseName == ex.name)
          .map((l) => SetEntry(
                setNumber: l.setNumber,
                weight: l.weight,
                reps: l.reps,
                setSeconds: l.setSeconds,
                restSeconds: l.restSeconds,
              ))
          .toList();
      s.completedExercises.add(
        CompletedExercise(exerciseName: ex.name, durationSeconds: duration, sets: setsForExercise, endElapsed: s.elapsed),
      );
    }

    s.completedSets += 1;

    if (isLastSetOfExercise && isLastExercise) {
      _finishWorkout(s.elapsed, s.templateId, s.completedExercises);
      return;
    }

    if (isLastSetOfExercise) {
      s.exIndex += 1;
      s.setIndex = 1;
    } else {
      s.setIndex += 1;
    }

    final nextEx = exerciseAt(tmpl, s, s.exIndex);
    final carried = prefill(nextEx.name, s.setIndex, sessionLogs: s.logs);
    s.phase = SessionPhase.resting;
    s.restElapsed = 0;
    s.currentWeight = carried.weight;
    s.currentReps = carried.reps;
    _rescheduleRestNotification();
    unawaited(_persistSession());
    notifyListeners();
  }

  void skipRest() {
    final s = session;
    if (s == null) return;
    final isNewExercise = s.exerciseStartExIndex != s.exIndex;
    s.pendingRestSeconds = s.restElapsed;
    s.phase = SessionPhase.working;
    s.restElapsed = 0;
    s.setStartElapsed = s.elapsed;
    if (isNewExercise) s.exerciseStartElapsed = s.elapsed;
    s.exerciseStartExIndex = s.exIndex;
    _rescheduleRestNotification();
    unawaited(_persistSession());
    notifyListeners();
  }

  void togglePause() {
    final s = session;
    if (s == null) return;
    s.paused = !s.paused;
    _rescheduleRestNotification();
    unawaited(_persistSession());
    notifyListeners();
  }

  /// Whether this is the one screen where swapping/excluding the current
  /// exercise is offered: the first (and only) time it's shown before
  /// starting work on it. For every exercise but the first, that's the rest
  /// right after the previous exercise's last set — by then `exIndex` has
  /// already moved on, so it's this exercise's upcoming first set. The very
  /// first exercise has no preceding rest to show it on, so its one chance
  /// is the working screen for its first set instead. Either way, it's
  /// offered exactly once per exercise rather than reappearing on both
  /// screens or every time the first set is revisited.
  bool _isFirstSightOfCurrentExercise(WorkoutSession s) {
    if (s.setIndex != 1) return false;
    if (s.exIndex == 0) return s.phase == SessionPhase.working;
    return s.phase == SessionPhase.resting;
  }

  /// Whether the current exercise can be swapped for another one in the same
  /// muscle group. Swapping mid-exercise would leave its logged sets split
  /// across two different exercise names, so this is only ever true on the
  /// one screen [_isFirstSightOfCurrentExercise] identifies.
  bool canSwapCurrentExercise() {
    final s = session;
    if (s == null || !_isFirstSightOfCurrentExercise(s)) return false;
    final tmpl = templateById(s.templateId);
    return _swapCandidates(tmpl, s).isNotEmpty;
  }

  /// Replaces the current exercise with a random alternative from the same
  /// muscle group, for this session only — the saved template is untouched.
  void swapCurrentExercise() {
    final s = session;
    if (s == null || !_isFirstSightOfCurrentExercise(s)) return;
    final tmpl = templateById(s.templateId);
    final current = exerciseAt(tmpl, s, s.exIndex);

    final candidates = _swapCandidates(tmpl, s);
    if (candidates.isEmpty) return;
    candidates.shuffle();
    final replacementName = candidates.first;

    s.exerciseOverrides[s.exIndex] = ExerciseTemplate(
      id: current.id,
      name: replacementName,
      sets: current.sets,
      setSeconds: current.setSeconds,
      restSeconds: current.restSeconds,
    );

    final carried = prefill(replacementName, s.setIndex, sessionLogs: s.logs);
    s.currentWeight = carried.weight;
    s.currentReps = carried.reps;
    unawaited(_persistSession());
    notifyListeners();
  }

  List<String> _swapCandidates(WorkoutTemplate tmpl, WorkoutSession s) {
    final current = exerciseAt(tmpl, s, s.exIndex);
    final group = ExerciseLibrary.groupOf(current.name);
    if (group == null) return const [];

    final alreadyUsed = {
      for (var i = 0; i < tmpl.exercises.length; i++) exerciseAt(tmpl, s, i).name,
    };
    return ExerciseLibrary.byGroup[group]!
        .where((name) => !alreadyUsed.contains(name) && !data.excludedExercises.contains(name))
        .where((name) => !tmpl.bodyweightOnly || ExerciseLibrary.bodyweightOnly.contains(name))
        .where((name) => !tmpl.weightsOnly || !ExerciseLibrary.bodyweightOnly.contains(name))
        .where((name) => !tmpl.favoritesOnly || data.favoriteExercises.contains(name))
        .where((name) => !tmpl.staleOnly || isExerciseStale(name))
        .toList();
  }

  bool isExerciseExcluded(String name) => data.excludedExercises.contains(name);

  void excludeExercise(String name) {
    data.excludedExercises.add(name);
    persist();
  }

  void includeExercise(String name) {
    data.excludedExercises.remove(name);
    persist();
  }

  bool isExerciseFavorite(String name) => data.favoriteExercises.contains(name);

  void toggleFavoriteExercise(String name) {
    if (!data.favoriteExercises.remove(name)) {
      data.favoriteExercises.add(name);
    }
    persist();
  }

  /// Whether [name] hasn't been trained in a while — never logged, or its
  /// most recent instance is more than two weeks old.
  bool isExerciseStale(String name) {
    final hist = data.exerciseHistory[name];
    if (hist == null || hist.isEmpty) return true;
    final latest = hist.map((i) => i.date).reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    return latest.compareTo(_dateString(daysAgo: 14)) < 0;
  }

  /// Marks the current exercise as excluded from now on, then immediately
  /// swaps in a replacement so the workout can continue — for when an
  /// exercise you can't do (no equipment, an injury, etc.) comes up.
  void markCurrentExerciseCantDo() {
    final s = session;
    if (s == null || !_isFirstSightOfCurrentExercise(s)) return;
    final tmpl = templateById(s.templateId);
    final current = exerciseAt(tmpl, s, s.exIndex);
    excludeExercise(current.name);
    swapCurrentExercise();
  }

  /// Schedules (or cancels) the "rest complete" notification to match the
  /// session's current rest state, so it always reflects the time actually
  /// remaining, e.g. when the user pauses or skips the rest early.
  void _rescheduleRestNotification() {
    final s = session;
    final tmpl = s == null ? null : templateById(s.templateId);
    if (s == null || tmpl == null || s.phase != SessionPhase.resting || s.paused) {
      unawaited(_restNotifications.cancelRestComplete());
      return;
    }

    final ex = exerciseAt(tmpl, s, s.exIndex);
    final remaining = ex.restSeconds - s.restElapsed;
    if (remaining <= 0) {
      unawaited(_restNotifications.cancelRestComplete());
      return;
    }

    unawaited(
      _restNotifications.scheduleRestComplete(afterSeconds: remaining, exerciseName: ex.name),
    );
  }

  void abandonWorkout() {
    _stopTimer();
    unawaited(_restNotifications.cancelRestComplete());
    session = null;
    screen = Screen.home;
    unawaited(_persistSession());
    notifyListeners();
  }

  void _finishWorkout(int durationSeconds, String templateId, List<CompletedExercise> completedExercises) {
    _stopTimer();
    unawaited(_restNotifications.cancelRestComplete());
    unawaited(Storage.saveSession(null));
    final tmpl = templateById(templateId);
    final targetSeconds = tmpl.targetMinutes * 60;
    final onPace = durationSeconds <= targetSeconds;
    final pctUnder = onPace ? (targetSeconds - durationSeconds) / math.max(targetSeconds, 1) : 0.0;
    final speedBonus = onPace ? math.min(50, (pctUnder * 2 * 50).round()) : 0;

    final today = _todayString();
    var streak = data.profile.streak;
    if (data.profile.lastCompletedDate != today) {
      final yesterday = _dateString(daysAgo: 1);
      streak = data.profile.lastCompletedDate == yesterday ? streak + 1 : 1;
    }
    final streakBonus = math.min(streak * 5, 50);
    const baseXp = 50;
    final xpEarned = baseXp + speedBonus + streakBonus;

    final sessionCount = data.profile.sessionCount + 1;
    final onPaceCount = data.profile.onPaceCount + (onPace ? 1 : 0);

    data.profile.totalXp += xpEarned;
    data.profile.streak = streak;
    data.profile.lastCompletedDate = today;
    data.profile.onPaceCount = onPaceCount;
    data.profile.sessionCount = sessionCount;

    data.history.insert(
      0,
      SessionHistoryEntry(
        date: today,
        templateName: tmpl.name,
        durationSeconds: durationSeconds,
        targetSeconds: targetSeconds,
        xpEarned: xpEarned,
        onPace: onPace,
        templateId: templateId,
        completedExercises: completedExercises,
      ),
    );
    if (data.history.length > 50) {
      data.history.removeRange(50, data.history.length);
    }

    for (final ce in completedExercises) {
      final arr = data.exerciseHistory[ce.exerciseName] ?? [];
      arr.add(ExerciseHistoryInstance(date: today, durationSeconds: ce.durationSeconds, sets: ce.sets));
      data.exerciseHistory[ce.exerciseName] = arr;
    }

    // Evaluated last, once history and exerciseHistory reflect this session,
    // since badge conditions are derived from the full data set rather than
    // tracked incrementally.
    final badgeEvaluation = evaluateBadges(data);
    data.profile.badges = badgeEvaluation.allEarnedIds;

    persist();
    summary = WorkoutSummary(
      templateId: templateId,
      durationSeconds: durationSeconds,
      targetSeconds: targetSeconds,
      onPace: onPace,
      xpEarned: xpEarned,
      baseXp: baseXp,
      speedBonus: speedBonus,
      streakBonus: streakBonus,
      streak: streak,
      unlockedNow: badgeEvaluation.newlyUnlocked,
      completedExercises: completedExercises,
    );
    session = null;
    screen = Screen.summary;
    notifyListeners();
  }

  // MARK: Template management

  void deleteTemplate(String id) {
    // Always keep at least one saved workout; temporary (unsaved random)
    // ones don't count toward that floor.
    final savedCount = data.templates.where((t) => !t.isTemporary).length;
    final target = _findTemplate(id);
    if (target != null && !target.isTemporary && savedCount <= 1) return;

    data.templates.removeWhere((t) => t.id == id);
    if (data.activeTemplateId == id) {
      final fallback = data.templates.where((t) => !t.isTemporary).isNotEmpty
          ? data.templates.firstWhere((t) => !t.isTemporary)
          : data.templates.first;
      data.activeTemplateId = fallback.id;
    }
    persist();
  }

  String newTemplate() {
    final id = _newId('t');
    data.templates.add(WorkoutTemplate(id: id, name: 'New workout', targetMinutes: 30, exercises: []));
    persist();
    return id;
  }

  static const _randomWorkoutRestSeconds = 90;

  /// The exercise count (1-8) whose [estimateTargetMinutes] lands closest to
  /// [targetMinutes] — rather than deriving a count directly from a division
  /// that, once rounded up to the nearest 15 minutes, could overshoot the
  /// request by a whole bucket (e.g. a flat lower bound of 3 exercises alone
  /// is already a ~45 minute workout, blowing past a 15 minute request).
  int _desiredExerciseCount(int targetMinutes) {
    const perExercise = 3 * (defaultSetSeconds + _randomWorkoutRestSeconds) + exerciseBufferSeconds;
    var bestCount = 1;
    var bestDiff = 1 << 30;
    for (var n = 1; n <= 8; n++) {
      final totalSeconds = n * perExercise - _randomWorkoutRestSeconds;
      final minutes = math.max(15, (totalSeconds / 60 / 15).ceil() * 15);
      final diff = (minutes - targetMinutes).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestCount = n;
      }
    }
    return bestCount;
  }

  /// The most recent date any exercise in each region of [group] was
  /// logged, keyed by region label — so region selection can prioritize
  /// whichever part of the muscle group hasn't been trained in the
  /// longest time (or never, which sorts first of all).
  Map<String, String> _lastTrainedByRegion(MuscleGroup group) {
    final lastTrained = <String, String>{};
    data.exerciseHistory.forEach((exerciseName, instances) {
      if (instances.isEmpty) return;
      if (ExerciseLibrary.groupOf(exerciseName) != group) return;
      final region = ExerciseLibrary.regionOf[exerciseName];
      if (region == null) return;

      final latest = instances.map((i) => i.date).reduce((a, b) => a.compareTo(b) > 0 ? a : b);
      final existing = lastTrained[region];
      if (existing == null || latest.compareTo(existing) > 0) {
        lastTrained[region] = latest;
      }
    });
    return lastTrained;
  }

  /// An exercise pool for [group], ordered so a short workout still
  /// samples across every region of the muscle group before repeating
  /// one, instead of the flat random pick risking e.g. three flat-bench
  /// chest variants and no fly or dip work. Regions are visited in
  /// least-recently-trained order first (never-trained regions first of
  /// all), so when there isn't room for every region, the most neglected
  /// ones win the available slots; exercises within a region are
  /// otherwise shuffled.
  List<String> _regionOrderedPool(MuscleGroup group, math.Random rng, bool Function(String) isEligible) {
    final regions = ExerciseLibrary.regionsOf(group);
    final lastTrained = _lastTrainedByRegion(group);
    final tieBreak = {for (final region in regions) region: rng.nextDouble()};

    final byRegion = {
      for (final region in regions)
        region: (ExerciseLibrary.byGroup[group]!
                .where((name) => ExerciseLibrary.regionOf[name] == region && isEligible(name))
                .toList()
              ..shuffle(rng)),
    };

    final orderedRegions = regions.toList()
      ..sort((a, b) {
        final dateA = lastTrained[a];
        final dateB = lastTrained[b];
        if (dateA == null && dateB == null) return tieBreak[a]!.compareTo(tieBreak[b]!);
        if (dateA == null) return -1;
        if (dateB == null) return 1;
        if (dateA != dateB) return dateA.compareTo(dateB);
        return tieBreak[a]!.compareTo(tieBreak[b]!);
      });

    // Round-robin merge: one exercise from each region per pass, so the
    // front of the merged list covers every region before any region
    // gets a second pick.
    final merged = <String>[];
    var progress = true;
    while (progress) {
      progress = false;
      for (final region in orderedRegions) {
        final pool = byRegion[region]!;
        if (pool.isEmpty) continue;
        merged.add(pool.removeAt(0));
        progress = true;
      }
    }
    return merged;
  }

  /// Builds a new workout template from a random selection of exercises
  /// matching [request], saves it, and returns its id so the caller can open
  /// it for review.
  String generateRandomWorkout(RandomWorkoutRequest request) {
    final groups = _resolveMuscleGroups(request);
    final rng = math.Random();

    // A full-body workout should cover every major muscle group without
    // repeating one, so it can never ask for more exercises than there are
    // groups to draw from — a longer target duration just falls short of
    // the request rather than doubling up on a group.
    final desiredCount =
        request.fullBody ? math.min(_desiredExerciseCount(request.targetMinutes), groups.length) : _desiredExerciseCount(request.targetMinutes);

    final pools = {
      for (final group in groups)
        group: _regionOrderedPool(
          group,
          rng,
          (name) =>
              !data.excludedExercises.contains(name) &&
              (!request.bodyweightOnly || ExerciseLibrary.bodyweightOnly.contains(name)) &&
              (!request.weightsOnly || !ExerciseLibrary.bodyweightOnly.contains(name)) &&
              (!request.favoritesOnly || data.favoriteExercises.contains(name)) &&
              (!request.staleOnly || isExerciseStale(name)),
        ),
    };
    final groupOrder = groups.toList()..shuffle(rng);

    final chosen = <ExerciseTemplate>[];
    while (chosen.length < desiredCount) {
      var madeProgress = false;
      for (final group in groupOrder) {
        if (chosen.length >= desiredCount) break;
        final pool = pools[group]!;
        if (pool.isEmpty) continue;
        final name = pool.removeAt(0);
        chosen.add(ExerciseTemplate(
          id: _newId('e'),
          name: name,
          sets: 3,
          setSeconds: defaultSetSeconds,
          restSeconds: _randomWorkoutRestSeconds,
        ));
        madeProgress = true;
      }
      if (!madeProgress) break;
    }

    final id = _newId('t');
    final template = WorkoutTemplate(
      id: id,
      name: _randomWorkoutName(request, groups),
      // Placeholder until the real estimate below; templates need a value
      // up front to construct.
      targetMinutes: request.targetMinutes,
      exercises: chosen,
      // Not shown on the Workouts screen until the user explicitly saves
      // it, from the summary screen or the Stats recent-sessions list.
      isTemporary: true,
      bodyweightOnly: request.bodyweightOnly,
      weightsOnly: request.weightsOnly,
      favoritesOnly: request.favoritesOnly,
      staleOnly: request.staleOnly,
    );
    // Reflect the exercises actually chosen, not just the requested
    // duration — the two can differ once the exercise pool runs out or
    // rounds to a different count.
    template.targetMinutes = estimateTargetMinutes(template);
    data.templates.add(template);
    persist();
    return id;
  }

  WorkoutTemplate? _findTemplate(String id) {
    for (final template in data.templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  /// Whether the template behind a completed session (or the current
  /// active one) is a not-yet-saved random workout that can still be added
  /// to the user's permanent workout list.
  bool canSaveTemplate(String? templateId) {
    if (templateId == null) return false;
    return _findTemplate(templateId)?.isTemporary ?? false;
  }

  /// Adds a randomly generated workout to the user's permanent workout
  /// list, so it now shows on the Workouts screen like any other template.
  void saveTemplateToMyWorkouts(String templateId) {
    final template = _findTemplate(templateId);
    if (template == null || !template.isTemporary) return;
    template.isTemporary = false;
    persist();
  }

  /// Whether the exercise at [exerciseId] within [templateId] has any
  /// same-muscle-group alternative left to swap in.
  bool canSwapTemplateExercise(String templateId, String exerciseId) {
    final tmpl = _findTemplate(templateId);
    if (tmpl == null) return false;
    return _templateSwapCandidates(tmpl, exerciseId).isNotEmpty;
  }

  /// Permanently replaces one exercise in a saved template with a random
  /// alternative from the same muscle group — unlike [swapCurrentExercise],
  /// which only swaps for the current session, this edits the template
  /// itself, so every future workout from this plan uses the replacement
  /// too. No-op if the template, exercise, or a candidate can't be found.
  void swapTemplateExercise(String templateId, String exerciseId) {
    final tmpl = _findTemplate(templateId);
    if (tmpl == null) return;
    final idx = tmpl.exercises.indexWhere((e) => e.id == exerciseId);
    if (idx == -1) return;
    final candidates = _templateSwapCandidates(tmpl, exerciseId);
    if (candidates.isEmpty) return;
    candidates.shuffle();
    final current = tmpl.exercises[idx];
    tmpl.exercises[idx] = ExerciseTemplate(
      id: current.id,
      name: candidates.first,
      sets: current.sets,
      setSeconds: current.setSeconds,
      restSeconds: current.restSeconds,
    );
    persist();
  }

  List<String> _templateSwapCandidates(WorkoutTemplate tmpl, String exerciseId) {
    String? currentName;
    for (final e in tmpl.exercises) {
      if (e.id == exerciseId) currentName = e.name;
    }
    if (currentName == null) return const [];
    final group = ExerciseLibrary.groupOf(currentName);
    if (group == null) return const [];

    final alreadyUsed = {for (final e in tmpl.exercises) e.name};
    return ExerciseLibrary.byGroup[group]!
        .where((name) => !alreadyUsed.contains(name) && !data.excludedExercises.contains(name))
        .where((name) => !tmpl.bodyweightOnly || ExerciseLibrary.bodyweightOnly.contains(name))
        .where((name) => !tmpl.weightsOnly || !ExerciseLibrary.bodyweightOnly.contains(name))
        .where((name) => !tmpl.favoritesOnly || data.favoriteExercises.contains(name))
        .where((name) => !tmpl.staleOnly || isExerciseStale(name))
        .toList();
  }

  Set<MuscleGroup> _resolveMuscleGroups(RandomWorkoutRequest request) {
    if (request.fullBody) return trainableMuscleGroups.toSet();
    if (request.neglectedOnly) return _leastRecentlyTrainedGroups(count: 3);
    if (request.groups.isNotEmpty) return request.groups;
    return trainableMuscleGroups.toSet();
  }

  /// Groups with no logged history sort first (most neglected), then the
  /// ones least recently trained, based on the most recent date any
  /// exercise in that group was logged.
  Set<MuscleGroup> _leastRecentlyTrainedGroups({required int count}) {
    final lastTrained = <MuscleGroup, String>{};
    data.exerciseHistory.forEach((exerciseName, instances) {
      if (instances.isEmpty) return;
      final group = ExerciseLibrary.groupOf(exerciseName);
      if (group == null) return;

      final latest = instances.map((i) => i.date).reduce((a, b) => a.compareTo(b) > 0 ? a : b);
      final existing = lastTrained[group];
      if (existing == null || latest.compareTo(existing) > 0) {
        lastTrained[group] = latest;
      }
    });

    final ranked = [...trainableMuscleGroups]
      ..sort((a, b) {
        final dateA = lastTrained[a];
        final dateB = lastTrained[b];
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return -1;
        if (dateB == null) return 1;
        return dateA.compareTo(dateB);
      });

    return ranked.take(count).toSet();
  }

  String _randomWorkoutName(RandomWorkoutRequest request, Set<MuscleGroup> groups) {
    final bw = request.bodyweightOnly ? 'Bodyweight ' : (request.weightsOnly ? 'Weighted ' : '');
    if (request.fullBody) return 'Random ${bw}Full Body Workout';
    if (request.neglectedOnly) return 'Random ${bw}Workout (Due For Training)';
    final label = groups.map((g) => g.label).join(' & ');
    return 'Random $bw$label Workout';
  }

  void saveTemplate(WorkoutTemplate template) {
    final idx = data.templates.indexWhere((t) => t.id == template.id);
    if (idx != -1) {
      data.templates[idx] = template;
      persist();
    }
  }

  void resetAll() {
    data = AppData();
    persist();
  }

  // MARK: Date helpers

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _dateString({required int daysAgo}) {
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
