import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Richer, sourced-from-fitnessprogramer.com guidance for one exercise.
class ExerciseTipsEntry {
  final List<String> howTo;
  final List<String> tips;
  final List<String> mistakes;

  const ExerciseTipsEntry({required this.howTo, required this.tips, required this.mistakes});

  bool get isEmpty => howTo.isEmpty && tips.isEmpty && mistakes.isEmpty;
}

/// Loaded once at startup (see [loadExerciseTipsData]) from
/// assets/exercise_tips.json, keyed by exercise name. Exercises without a
/// scraped match are simply absent.
Map<String, ExerciseTipsEntry> exerciseTipsData = {};

/// Reads and parses assets/exercise_tips.json into [exerciseTipsData].
/// Safe to call even if the asset is missing or malformed — the app just
/// falls back to the built-in tip bullets for every exercise in that case.
Future<void> loadExerciseTipsData() async {
  try {
    final raw = await rootBundle.loadString('assets/exercise_tips.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    exerciseTipsData = decoded.map((name, value) {
      final v = value as Map<String, dynamic>;
      List<String> stringList(String key) => (v[key] as List? ?? const []).map((e) => e.toString()).toList();
      return MapEntry(
        name,
        ExerciseTipsEntry(howTo: stringList('howTo'), tips: stringList('tips'), mistakes: stringList('mistakes')),
      );
    });
  } catch (_) {
    exerciseTipsData = {};
  }
}
