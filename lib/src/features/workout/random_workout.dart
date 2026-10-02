import 'exercise_library.dart';

/// What the user asked for when generating a random workout.
///
/// Exactly one of [fullBody], [neglectedOnly], or a non-empty [groups] is
/// meant to be set at a time; the UI enforces that as mutually-exclusive
/// selection modes.
class RandomWorkoutRequest {
  final bool fullBody;
  final bool neglectedOnly;
  final Set<MuscleGroup> groups;
  final int targetMinutes;

  /// When true, only bodyweight exercises (see [ExerciseLibrary.bodyweightOnly])
  /// are eligible — for a workout with no equipment at all.
  final bool bodyweightOnly;

  /// When true, only exercises the user has favorited are eligible.
  final bool favoritesOnly;

  /// When true, only exercises that haven't been trained in a while (or
  /// ever) are eligible.
  final bool staleOnly;

  const RandomWorkoutRequest({
    this.fullBody = false,
    this.neglectedOnly = false,
    this.groups = const {},
    required this.targetMinutes,
    this.bodyweightOnly = false,
    this.favoritesOnly = false,
    this.staleOnly = false,
  });
}
