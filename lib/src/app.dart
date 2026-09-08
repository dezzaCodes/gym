import 'package:flutter/material.dart';

import 'bootstrap.dart';
import 'features/workout/app_state.dart';
import 'features/workout/root_view.dart';
import 'features/workout/theme.dart';

class App extends StatelessWidget {
  const App({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Iron Clock',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.panel,
        ),
      ),
      home: _WorkoutHome(bootstrap: bootstrap),
    );
  }
}

class _WorkoutHome extends StatefulWidget {
  const _WorkoutHome({required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  State<_WorkoutHome> createState() => _WorkoutHomeState();
}

class _WorkoutHomeState extends State<_WorkoutHome> {
  late final WorkoutAppState app;

  @override
  void initState() {
    super.initState();
    app = WorkoutAppState(
      authService: widget.bootstrap.authService,
      cloudRepository: widget.bootstrap.cloudWorkoutRepository,
    );
  }

  @override
  void dispose() {
    app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        if (!app.loaded) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        return RootView(app: app);
      },
    );
  }
}
