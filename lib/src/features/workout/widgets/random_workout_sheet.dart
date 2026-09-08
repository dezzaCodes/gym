import 'package:flutter/material.dart';
import '../exercise_library.dart';
import '../random_workout.dart';
import '../theme.dart';

const _durationPresets = [15, 30, 45, 60, 90];
const _defaultMinutes = 45;

/// Opens the muscle-group and duration picker for the random workout
/// generator, resolving to the user's request, or null if dismissed.
Future<RandomWorkoutRequest?> showRandomWorkoutSheet(BuildContext context) {
  return showModalBottomSheet<RandomWorkoutRequest>(
    context: context,
    backgroundColor: AppColors.panel,
    isScrollControlled: true,
    builder: (context) => const _RandomWorkoutSheet(),
  );
}

class _RandomWorkoutSheet extends StatefulWidget {
  const _RandomWorkoutSheet();

  @override
  State<_RandomWorkoutSheet> createState() => _RandomWorkoutSheetState();
}

class _RandomWorkoutSheetState extends State<_RandomWorkoutSheet> {
  final Set<MuscleGroup> _selectedGroups = {};
  bool _fullBody = false;
  bool _neglected = false;
  bool _bodyweightOnly = false;
  int _minutes = _defaultMinutes;

  void _toggleGroup(MuscleGroup group) {
    setState(() {
      _fullBody = false;
      _neglected = false;
      if (!_selectedGroups.remove(group)) {
        _selectedGroups.add(group);
      }
    });
  }

  void _toggleFullBody() {
    setState(() {
      _fullBody = !_fullBody;
      if (_fullBody) {
        _neglected = false;
        _selectedGroups.clear();
      }
    });
  }

  void _toggleNeglected() {
    setState(() {
      _neglected = !_neglected;
      if (_neglected) {
        _fullBody = false;
        _selectedGroups.clear();
      }
    });
  }

  bool get _canGenerate => _fullBody || _neglected || _selectedGroups.isNotEmpty;

  void _done() {
    Navigator.pop(
      context,
      RandomWorkoutRequest(
        fullBody: _fullBody,
        neglectedOnly: _neglected,
        groups: _selectedGroups,
        targetMinutes: _minutes,
        bodyweightOnly: _bodyweightOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Random workout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 16),
            const Text('Muscle groups', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final group in trainableMuscleGroups)
                  _chip(label: group.label, selected: _selectedGroups.contains(group), onTap: () => _toggleGroup(group)),
                _chip(label: 'Full body', selected: _fullBody, onTap: _toggleFullBody),
                _chip(label: "Haven't trained in a while", selected: _neglected, onTap: _toggleNeglected),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Equipment', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            _chip(
              label: 'No weights (bodyweight only)',
              selected: _bodyweightOnly,
              onTap: () => setState(() => _bodyweightOnly = !_bodyweightOnly),
            ),
            const SizedBox(height: 20),
            const Text('Duration (minutes)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durationPresets.map((minutes) {
                return _chip(
                  label: '$minutes min',
                  selected: _minutes == minutes,
                  onTap: () => setState(() => _minutes = minutes),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              onPressed: _canGenerate ? _done : null,
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({required String label, required bool selected, required VoidCallback onTap}) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accent,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(color: selected ? AppColors.background : AppColors.textMuted, fontSize: 13),
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.accent : AppColors.border)),
    );
  }
}
