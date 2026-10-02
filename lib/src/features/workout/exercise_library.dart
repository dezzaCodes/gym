/// The muscle groups exercises are organized under, both for the exercise
/// picker and for the random workout generator.
enum MuscleGroup { chest, back, shoulders, legs, arms, core, functional }

extension MuscleGroupX on MuscleGroup {
  String get label {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.legs:
        return 'Legs';
      case MuscleGroup.arms:
        return 'Arms';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.functional:
        return 'Functional';
    }
  }
}

/// The muscle groups the random workout generator can target. Functional
/// and Olympic lifts are searchable in the exercise picker but excluded
/// from random generation, since they're often more technical or
/// equipment-heavy than a "surprise me" pick should default to.
const trainableMuscleGroups = [
  MuscleGroup.chest,
  MuscleGroup.back,
  MuscleGroup.shoulders,
  MuscleGroup.legs,
  MuscleGroup.arms,
  MuscleGroup.core,
];

/// A curated library of common exercises, grouped by muscle group, for the
/// exercise picker and the random workout generator.
class ExerciseLibrary {
  static const Map<MuscleGroup, List<String>> byGroup = {
    MuscleGroup.chest: [
      'Bench Press',
      'Incline Bench Press',
      'Decline Bench Press',
      'Dumbbell Bench Press',
      'Incline Dumbbell Press',
      'Decline Dumbbell Press',
      'Push-Up',
      'Dumbbell Fly',
      'Cable Fly',
      'Chest Dip',
      'Machine Chest Press',
      'Decline Push-Up',
    ],
    MuscleGroup.back: [
      'Deadlift',
      'Romanian Deadlift',
      'Sumo Deadlift',
      'Trap Bar Deadlift',
      'Rack Pull',
      'Good Morning',
      'Back Extension',
      'Pull-Up',
      'Chin-Up',
      'Lat Pulldown',
      'Barbell Row',
      'Pendlay Row',
      'Dumbbell Row',
      'T-Bar Row',
      'Seated Cable Row',
      'Chest-Supported Row',
      'Face Pull',
      'Inverted Row',
      'Superman',
    ],
    MuscleGroup.shoulders: [
      'Overhead Press',
      'Seated Dumbbell Press',
      'Arnold Press',
      'Push Press',
      'Landmine Press',
      'Lateral Raise',
      'Front Raise',
      'Rear Delt Fly',
      'Upright Row',
      'Shrug',
      'Pike Push-Up',
      'Prone Reverse Fly',
    ],
    MuscleGroup.legs: [
      'Squat',
      'Back Squat',
      'Front Squat',
      'Goblet Squat',
      'Hack Squat',
      'Sissy Squat',
      'Zercher Squat',
      'Bulgarian Split Squat',
      'Walking Lunge',
      'Reverse Lunge',
      'Step-Up',
      'Leg Press',
      'Leg Extension',
      'Leg Curl',
      'Nordic Curl',
      'Hip Thrust',
      'Glute Bridge',
      'Calf Raise',
      'Seated Calf Raise',
    ],
    MuscleGroup.arms: [
      'Bicep Curl',
      'Hammer Curl',
      'Preacher Curl',
      'Concentration Curl',
      'Cable Curl',
      'EZ Bar Curl',
      'Reverse Curl',
      'Wrist Curl',
      'Tricep Pushdown',
      'Skull Crusher',
      'Overhead Tricep Extension',
      'Cable Overhead Extension',
      'Close-Grip Bench Press',
      'Tricep Dip',
      'Diamond Push-Up',
    ],
    MuscleGroup.core: [
      'Plank',
      'Side Plank',
      'Crunch',
      'Sit-Up',
      'Hanging Leg Raise',
      'Hanging Knee Raise',
      'Russian Twist',
      'Cable Woodchopper',
      'Ab Wheel Rollout',
      'Mountain Climber',
      'Dead Bug',
      'Bicycle Crunch',
      'V-Up',
      'Pallof Press',
    ],
    MuscleGroup.functional: [
      'Kettlebell Swing',
      'Clean and Jerk',
      'Snatch',
      'Power Clean',
      "Farmer's Carry",
      'Battle Ropes',
      'Box Jump',
      'Burpee',
      'Wall Ball',
      'Thruster',
      'Turkish Get-Up',
      'Medicine Ball Slam',
      'Sled Push',
      'Sled Pull',
    ],
  };

  static MuscleGroup? groupOf(String exerciseName) {
    for (final entry in byGroup.entries) {
      if (entry.value.contains(exerciseName)) return entry.key;
    }
    return null;
  }

  /// Which part of its muscle group each exercise emphasizes — e.g. chest
  /// splits into upper/middle/lower/inner — so the random workout
  /// generator can aim for complete coverage of a selected muscle group
  /// instead of, say, three flat-bench variants and nothing else. Not
  /// shown in the UI: the user only ever picks the muscle group itself.
  static const Map<String, String> regionOf = {
    // Chest
    'Incline Bench Press': 'Upper Chest',
    'Incline Dumbbell Press': 'Upper Chest',
    'Bench Press': 'Middle Chest',
    'Dumbbell Bench Press': 'Middle Chest',
    'Push-Up': 'Middle Chest',
    'Machine Chest Press': 'Middle Chest',
    'Decline Bench Press': 'Lower Chest',
    'Decline Dumbbell Press': 'Lower Chest',
    'Chest Dip': 'Lower Chest',
    'Dumbbell Fly': 'Inner Chest',
    'Cable Fly': 'Inner Chest',
    'Decline Push-Up': 'Upper Chest',
    // Back
    'Pull-Up': 'Lats',
    'Chin-Up': 'Lats',
    'Lat Pulldown': 'Lats',
    'Barbell Row': 'Mid-Back',
    'Pendlay Row': 'Mid-Back',
    'Dumbbell Row': 'Mid-Back',
    'T-Bar Row': 'Mid-Back',
    'Seated Cable Row': 'Mid-Back',
    'Chest-Supported Row': 'Mid-Back',
    'Inverted Row': 'Mid-Back',
    'Deadlift': 'Lower Back',
    'Romanian Deadlift': 'Lower Back',
    'Sumo Deadlift': 'Lower Back',
    'Trap Bar Deadlift': 'Lower Back',
    'Rack Pull': 'Lower Back',
    'Good Morning': 'Lower Back',
    'Back Extension': 'Lower Back',
    'Superman': 'Lower Back',
    'Face Pull': 'Rear Delts',
    // Shoulders
    'Overhead Press': 'Front Delts',
    'Seated Dumbbell Press': 'Front Delts',
    'Arnold Press': 'Front Delts',
    'Push Press': 'Front Delts',
    'Landmine Press': 'Front Delts',
    'Front Raise': 'Front Delts',
    'Pike Push-Up': 'Front Delts',
    'Lateral Raise': 'Side Delts',
    'Upright Row': 'Side Delts',
    'Rear Delt Fly': 'Rear Delts',
    'Prone Reverse Fly': 'Rear Delts',
    'Shrug': 'Traps',
    // Legs
    'Squat': 'Quads',
    'Back Squat': 'Quads',
    'Front Squat': 'Quads',
    'Goblet Squat': 'Quads',
    'Hack Squat': 'Quads',
    'Sissy Squat': 'Quads',
    'Zercher Squat': 'Quads',
    'Leg Press': 'Quads',
    'Leg Extension': 'Quads',
    'Leg Curl': 'Hamstrings',
    'Nordic Curl': 'Hamstrings',
    'Bulgarian Split Squat': 'Glutes',
    'Walking Lunge': 'Glutes',
    'Reverse Lunge': 'Glutes',
    'Step-Up': 'Glutes',
    'Hip Thrust': 'Glutes',
    'Glute Bridge': 'Glutes',
    'Calf Raise': 'Calves',
    'Seated Calf Raise': 'Calves',
    // Arms — biceps and triceps each split by which head the movement
    // biases, same as the other groups split by muscle region.
    'Bicep Curl': 'Biceps (Long Head)',
    'Cable Curl': 'Biceps (Long Head)',
    'EZ Bar Curl': 'Biceps (Long Head)',
    'Preacher Curl': 'Biceps (Short Head)',
    'Concentration Curl': 'Biceps (Short Head)',
    'Hammer Curl': 'Brachialis',
    'Reverse Curl': 'Brachialis',
    'Wrist Curl': 'Forearms',
    'Overhead Tricep Extension': 'Triceps (Long Head)',
    'Cable Overhead Extension': 'Triceps (Long Head)',
    'Skull Crusher': 'Triceps (Long Head)',
    'Tricep Pushdown': 'Triceps (Lateral Head)',
    'Diamond Push-Up': 'Triceps (Lateral Head)',
    'Close-Grip Bench Press': 'Triceps (Medial Head)',
    'Tricep Dip': 'Triceps (Medial Head)',
    // Core
    'Crunch': 'Upper Abs',
    'Sit-Up': 'Upper Abs',
    'Bicycle Crunch': 'Upper Abs',
    'V-Up': 'Upper Abs',
    'Hanging Leg Raise': 'Lower Abs',
    'Hanging Knee Raise': 'Lower Abs',
    'Mountain Climber': 'Lower Abs',
    'Dead Bug': 'Lower Abs',
    'Side Plank': 'Obliques',
    'Russian Twist': 'Obliques',
    'Cable Woodchopper': 'Obliques',
    'Plank': 'Deep Core',
    'Ab Wheel Rollout': 'Deep Core',
    'Pallof Press': 'Deep Core',
  };

  /// The distinct regions of [group], in the order they first appear in
  /// [byGroup] — used purely to iterate a group's regions, not to rank
  /// them (staleness ranking happens separately).
  static List<String> regionsOf(MuscleGroup group) {
    final seen = <String>[];
    for (final name in byGroup[group] ?? const []) {
      final region = regionOf[name];
      if (region != null && !seen.contains(region)) seen.add(region);
    }
    return seen;
  }

  /// Exercises from [byGroup] that need no added weight or resistance —
  /// just your own bodyweight (plus, for a few, a bar or dip station to
  /// hang from). Used to filter the random workout generator for a
  /// no-equipment session.
  static const Set<String> bodyweightOnly = {
    'Push-Up',
    'Chest Dip',
    'Decline Push-Up',
    'Pull-Up',
    'Chin-Up',
    'Inverted Row',
    'Superman',
    'Pike Push-Up',
    'Prone Reverse Fly',
    'Squat',
    'Bulgarian Split Squat',
    'Walking Lunge',
    'Reverse Lunge',
    'Step-Up',
    'Nordic Curl',
    'Glute Bridge',
    'Calf Raise',
    'Tricep Dip',
    'Diamond Push-Up',
    'Plank',
    'Side Plank',
    'Crunch',
    'Sit-Up',
    'Hanging Leg Raise',
    'Hanging Knee Raise',
    'Mountain Climber',
    'Dead Bug',
    'Bicycle Crunch',
    'V-Up',
    'Burpee',
    'Box Jump',
  };
}
