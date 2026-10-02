import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/bootstrap.dart';
import 'src/features/workout/exercise_tips_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.initialize();
  await loadExerciseTipsData();
  runApp(App(bootstrap: bootstrap));
}
