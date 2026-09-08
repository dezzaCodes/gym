import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iron_clock/src/app.dart';
import 'package:iron_clock/src/bootstrap.dart';
import 'package:iron_clock/src/features/workout/app_state.dart';
import 'package:iron_clock/src/features/workout/exercise_library.dart';
import 'package:iron_clock/src/features/workout/models.dart';
import 'package:iron_clock/src/features/workout/random_workout.dart';
import 'package:iron_clock/src/features/workout/widgets/exercise_chart.dart';

/// Drives whatever active workout is on screen through to its summary,
/// regardless of how many exercises or sets it has — taps "Finish set"
/// whenever it's showing, and "Skip rest" / "Start next set" otherwise.
Future<void> _completeActiveWorkout(WidgetTester tester, {int maxSteps = 60}) async {
  for (var i = 0; i < maxSteps; i++) {
    if (find.text('Done').evaluate().isNotEmpty) return;

    Finder? next;
    if (find.text('Finish set').evaluate().isNotEmpty) {
      next = find.text('Finish set');
    } else if (find.text('Skip rest').evaluate().isNotEmpty) {
      next = find.text('Skip rest');
    } else if (find.text('Start next set').evaluate().isNotEmpty) {
      next = find.text('Start next set');
    }
    if (next == null) return;

    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('renders the home screen with a default workout', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Iron Clock'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Cross-device sync requires Firebase'),
      findsOneWidget,
    );
  });

  testWidgets('tips show during both the working set and the rest timer', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    expect(find.text('Working set'), findsOneWidget);
    expect(find.textContaining('Tips for'), findsOneWidget);
    expect(find.text('On pace'), findsOneWidget);

    await tester.ensureVisible(find.text('Finish set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish set'));
    await tester.pumpAndSettle();

    expect(find.text('Working set'), findsNothing);
    expect(find.textContaining('Tips for'), findsOneWidget);
  });

  testWidgets('swap exercise replaces the current exercise with one from the same muscle group', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    // Push Day's first exercise, Bench Press, is the only Chest exercise in
    // the template, so a swap is guaranteed to pick a different one.
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Swap exercise'), findsOneWidget);

    await tester.ensureVisible(find.text('Swap exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Swap exercise'));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsNothing);
    expect(find.text('Swap exercise'), findsOneWidget);
  });

  testWidgets("marking an exercise as can't do excludes it and swaps it out immediately", (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);

    await tester.ensureVisible(find.textContaining("Can't do this"));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining("Can't do this"));
    await tester.pumpAndSettle();

    // Swapped out immediately, so the workout continues without it.
    expect(find.text('Bench Press'), findsNothing);

    await tester.ensureVisible(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Excluded exercises'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);

    await tester.ensureVisible(find.text('Include again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Include again'));
    await tester.pumpAndSettle();

    expect(find.text('Excluded exercises'), findsNothing);
  });

  testWidgets('swap exercise option disappears after the first set is completed', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    expect(find.text('Swap exercise'), findsOneWidget);

    await tester.ensureVisible(find.text('Finish set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish set'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Skip rest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip rest'));
    await tester.pumpAndSettle();

    // Bench Press has 4 sets, so we're now on set 2 of the same exercise.
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Working set'), findsOneWidget);
    expect(find.text('Swap exercise'), findsNothing);
  });

  testWidgets('edit workout screen hides set time but keeps target time editable', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune).first);
    await tester.pumpAndSettle();

    expect(find.text('Set time (sec)'), findsNothing);
    expect(find.text('Target time (minutes)'), findsOneWidget);
  });

  testWidgets('completing a set transitions into rest and back to working', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Finish set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish set'));
    await tester.pumpAndSettle();

    expect(find.text('Working set'), findsNothing);
    expect(find.textContaining('rest'), findsWidgets);

    await tester.ensureVisible(find.text('Skip rest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip rest'));
    await tester.pumpAndSettle();

    expect(find.text('Working set'), findsOneWidget);
  });

  testWidgets('prefill carries values forward within a session when the exercise has no history', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('weight_0_1')), '100');
    await tester.enterText(find.byKey(const ValueKey('reps_0_1')), '8');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Finish set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish set'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Skip rest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip rest'));
    await tester.pumpAndSettle();

    // Bench Press has never been logged before, so set 2 should carry
    // forward set 1's values from this session rather than starting blank.
    // Checked on the fields directly since "100" can also appear as an
    // axis tick once the exercise chart is showing live data.
    final weightField = tester.widget<TextFormField>(find.byKey(const ValueKey('weight_0_2')));
    final repsField = tester.widget<TextFormField>(find.byKey(const ValueKey('reps_0_2')));
    expect(weightField.initialValue, '100');
    expect(repsField.initialValue, '8');
  });

  testWidgets('exercise chart updates immediately after finishing a set', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    expect(find.textContaining('History for'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('weight_0_1')), '100');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Finish set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish set'));
    await tester.pumpAndSettle();

    // The chart should reflect the just-finished set immediately, without
    // waiting for the whole workout to end and get persisted.
    expect(find.textContaining('History for'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('exercise picker lets you search and add an exercise from the library', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune).first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();

    expect(find.text('Choose an exercise'), findsOneWidget);
    expect(find.text('Chest'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('exercisePickerSearch')), 'squat');
    await tester.pumpAndSettle();

    expect(find.text('Squat'), findsOneWidget);

    await tester.tap(find.text('Squat'));
    await tester.pumpAndSettle();

    expect(find.text('Choose an exercise'), findsNothing);
    expect(find.text('Squat'), findsOneWidget);
  });

  testWidgets('random workout generator makes the generated workout current, then start begins it', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Random workout'));
    await tester.pumpAndSettle();

    expect(find.text('Random workout'), findsWidgets);

    await tester.tap(find.text('Legs'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Back on Home, with the generated workout now current — not started
    // yet, and not dropped into the editor either.
    expect(find.text('Working set'), findsNothing);
    expect(find.text('Random Legs Workout'), findsOneWidget);

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    expect(find.text('Working set'), findsOneWidget);
  });

  testWidgets('each random workout duration preset generates a workout estimated at that same duration', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final app = WorkoutAppState();
    while (!app.loaded) {
      await tester.pump(const Duration(milliseconds: 1));
    }

    for (final minutes in [15, 30, 45, 60, 90]) {
      final id = app.generateRandomWorkout(RandomWorkoutRequest(fullBody: true, targetMinutes: minutes));
      final tmpl = app.templateById(id);
      expect(tmpl.targetMinutes, minutes, reason: 'requested $minutes minutes');
    }

    app.dispose();
  });

  testWidgets('a bodyweight-only random workout picks exclusively bodyweight exercises', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final app = WorkoutAppState();
    while (!app.loaded) {
      await tester.pump(const Duration(milliseconds: 1));
    }

    for (var i = 0; i < 10; i++) {
      final id = app.generateRandomWorkout(
        const RandomWorkoutRequest(fullBody: true, targetMinutes: 45, bodyweightOnly: true),
      );
      final tmpl = app.templateById(id);
      expect(tmpl.exercises, isNotEmpty);
      for (final ex in tmpl.exercises) {
        expect(ExerciseLibrary.bodyweightOnly.contains(ex.name), isTrue, reason: '${ex.name} is not bodyweight-only');
      }
    }

    app.dispose();
  });

  testWidgets('exercise chart plots set number on the x-axis with one line per date', (
    WidgetTester tester,
  ) async {
    final history = [
      ExerciseHistoryInstance(date: '2024-01-01', durationSeconds: 200, sets: [
        SetEntry(setNumber: 1, weight: 100, reps: 8, setSeconds: 40, restSeconds: null),
        SetEntry(setNumber: 2, weight: 100, reps: 8, setSeconds: 42, restSeconds: 90),
      ]),
      ExerciseHistoryInstance(date: '2024-01-08', durationSeconds: 210, sets: [
        SetEntry(setNumber: 1, weight: 105, reps: 8, setSeconds: 38, restSeconds: null),
        SetEntry(setNumber: 2, weight: 105, reps: 7, setSeconds: 44, restSeconds: 88),
      ]),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: ExerciseChart(history: history))),
      ),
    );
    await tester.pumpAndSettle();

    // Exactly one chart, regardless of how much history exists.
    expect(find.byType(LineChart), findsOneWidget);

    // Legend shows one entry per date (colors distinguish sessions now that
    // set number is the x-axis).
    expect(find.text('01-01'), findsOneWidget);
    expect(find.text('01-08'), findsOneWidget);
  });

  testWidgets('exercise chart gives same-day repeats their own line instead of merging them', (
    WidgetTester tester,
  ) async {
    final history = [
      ExerciseHistoryInstance(date: '2024-01-01', durationSeconds: 200, sets: [
        SetEntry(setNumber: 1, weight: 100, reps: 8),
      ]),
      ExerciseHistoryInstance(date: '2024-01-01', durationSeconds: 180, sets: [
        SetEntry(setNumber: 1, weight: 110, reps: 8),
      ]),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: ExerciseChart(history: history))),
      ),
    );
    await tester.pumpAndSettle();

    // Still one chart widget, but two distinct, separately labeled lines —
    // neither occurrence's data is dropped or merged into the other.
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('01-01 #1'), findsOneWidget);
    expect(find.text('01-01 #2'), findsOneWidget);
  });

  testWidgets('workouts is reachable from bottom navigation and start/random stay pinned', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pinned outside the scroll area, so both are reachable without
    // needing to scroll past the level/exercise panels first.
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.text('Random workout'), findsOneWidget);

    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();

    expect(find.text('Your workouts'), findsOneWidget);
    expect(find.text('New workout'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Start workout'), findsOneWidget);
  });

  testWidgets('finishing a workout earns badges shown on the summary and stats screens', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    await _completeActiveWorkout(tester);

    // Finishing any workout always earns the first sessions-tier badge.
    expect(find.text('New badges'), findsOneWidget);
    expect(find.text('First Rep'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    final earnedCountText = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .firstWhere((s) => s.contains('/100'));
    final earnedCount = int.parse(earnedCountText.split('/').first);
    expect(earnedCount, greaterThan(0));
  });

  testWidgets('random workouts stay off the workouts list until saved from the summary screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Random workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Legs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    expect(find.text('Random Legs Workout'), findsNothing);
    expect(find.text('Leg Day'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    await _completeActiveWorkout(tester);

    await tester.ensureVisible(find.text('Add to workouts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to workouts'));
    await tester.pumpAndSettle();
    expect(find.text('Add to workouts'), findsNothing);

    await tester.ensureVisible(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    expect(find.text('Random Legs Workout'), findsOneWidget);
  });

  testWidgets('workout overview is collapsed by default and expands to show every exercise', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    // Collapsed: only the current exercise's overview row, showing "Set 1
    // of 4" instead of a completed-sets count since it's the active one.
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Set 1 of 4'), findsOneWidget);
    expect(find.text('Overhead Press'), findsNothing);

    await tester.tap(find.text('Workout overview'));
    await tester.pumpAndSettle();

    // Expanded: every Push Day exercise now shows in the overview list.
    expect(find.text('Overhead Press'), findsOneWidget);
    expect(find.text('Incline Dumbbell Press'), findsOneWidget);
    expect(find.text('Tricep Pushdown'), findsOneWidget);

    await tester.tap(find.text('Workout overview'));
    await tester.pumpAndSettle();

    expect(find.text('Overhead Press'), findsNothing);
  });

  testWidgets('an in-progress workout is restored after the app restarts', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    final weightField = find.byKey(const ValueKey('weight_0_1'));
    await tester.ensureVisible(weightField);
    await tester.enterText(weightField, '135');
    await tester.pumpAndSettle();

    final finishSet = find.text('Finish set');
    await tester.ensureVisible(finishSet);
    await tester.tap(finishSet);
    await tester.pumpAndSettle();
    // Let the fire-and-forget session save finish writing to storage.
    await tester.pump(const Duration(milliseconds: 50));

    // Simulate the app being fully closed and relaunched: a fresh App
    // widget (and fresh WorkoutAppState) reading from the same on-disk
    // storage.
    await tester.pumpWidget(
      const App(
        bootstrap: AppBootstrap(
          firebaseReady: false,
          statusMessage: 'Firebase is not configured yet.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Straight back into the same workout, on set 2 with rest already
    // showing, rather than dropped back to the home screen.
    expect(find.text('Start workout'), findsNothing);
    expect(find.text('Set 2 of 4'), findsOneWidget);
  });
}
