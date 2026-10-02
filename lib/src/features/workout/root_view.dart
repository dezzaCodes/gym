import 'package:flutter/material.dart';
import 'app_state.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/workouts_screen.dart';
import 'screens/edit_workout_screen.dart';
import 'screens/active_workout_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/badges_screen.dart';
import 'screens/exercises_screen.dart';
import 'screens/exercise_detail_screen.dart';

class RootView extends StatelessWidget {
  final WorkoutAppState app;
  const RootView({super.key, required this.app});

  bool get _showNav =>
      app.screen == Screen.home ||
      app.screen == Screen.workouts ||
      app.screen == Screen.progress ||
      app.screen == Screen.stats;

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (app.screen) {
      case Screen.home:
        body = HomeScreen(app: app);
        break;
      case Screen.workouts:
        body = WorkoutsScreen(app: app);
        break;
      case Screen.edit:
        body = EditWorkoutScreen(app: app);
        break;
      case Screen.active:
        body = app.session != null ? ActiveWorkoutScreen(app: app) : const SizedBox.shrink();
        break;
      case Screen.summary:
        body = SummaryScreen(app: app);
        break;
      case Screen.progress:
        body = ProgressScreen(app: app);
        break;
      case Screen.stats:
        body = StatsScreen(app: app);
        break;
      case Screen.badges:
        body = BadgesScreen(app: app);
        break;
      case Screen.exercises:
        body = ExercisesScreen(app: app);
        break;
      case Screen.exerciseDetail:
        body = ExerciseDetailScreen(app: app);
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(bottom: !_showNav, child: body),
      bottomNavigationBar: _showNav
          ? DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.panel,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    _navButton(Icons.home, 'Home', Screen.home),
                    _navButton(Icons.dashboard_customize_outlined, 'Workouts', Screen.workouts),
                    _navButton(Icons.show_chart, 'Progress', Screen.progress),
                    _navButton(Icons.bar_chart, 'Stats', Screen.stats),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _navButton(IconData icon, String label, Screen target) {
    final active = app.screen == target;
    final color = active ? AppColors.accent : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: () => app.goTo(target),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
