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

  /// Exercises from [byGroup] that need no added weight or resistance —
  /// just your own bodyweight (plus, for a few, a bar or dip station to
  /// hang from). Used to filter the random workout generator for a
  /// no-equipment session.
  static const Set<String> bodyweightOnly = {
    'Push-Up',
    'Chest Dip',
    'Pull-Up',
    'Chin-Up',
    'Pike Push-Up',
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
