import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/exercise_picker_sheet.dart';

class EditWorkoutScreen extends StatefulWidget {
  final WorkoutAppState app;
  const EditWorkoutScreen({super.key, required this.app});

  @override
  State<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends State<EditWorkoutScreen> {
  late WorkoutTemplate draft;
  late final TextEditingController _targetMinutesController;

  // Once the user directly edits the target time, stop overwriting it with
  // a fresh estimate as they tweak sets or rest.
  bool _targetMinutesEdited = false;

  @override
  void initState() {
    super.initState();
    final id = widget.app.editingTemplateId ?? widget.app.data.activeTemplateId;
    draft = widget.app.templateById(id).copy();
    _targetMinutesController = TextEditingController(text: draft.targetMinutes.toString());
    // Editing a workout that already has exercises means a target time was
    // already chosen for it; only a brand-new, empty workout should have its
    // target time live-estimated as exercises are added.
    _targetMinutesEdited = draft.exercises.isNotEmpty;
  }

  @override
  void dispose() {
    _targetMinutesController.dispose();
    super.dispose();
  }

  void _updateEstimateIfNeeded() {
    if (_targetMinutesEdited) return;
    draft.targetMinutes = estimateTargetMinutes(draft);
    _targetMinutesController.text = draft.targetMinutes.toString();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.text), onPressed: () => app.goTo(app.editReturn)),
              const Text('Edit workout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
            ],
          ),
          const SizedBox(height: 8),
          PanelBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Workout name', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                TextFormField(
                  initialValue: draft.name,
                  style: const TextStyle(color: AppColors.text),
                  decoration: ironFieldDecoration(),
                  onChanged: (v) => setState(() => draft.name = v),
                ),
                const SizedBox(height: 12),
                const Text('Target time (minutes)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _targetMinutesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.text),
                  decoration: ironFieldDecoration(),
                  onChanged: (v) => setState(() {
                    draft.targetMinutes = int.tryParse(v) ?? 0;
                    _targetMinutesEdited = true;
                  }),
                ),
                if (!_targetMinutesEdited) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Estimated from sets and rest below. Edit it directly to override.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...draft.exercises.asMap().entries.map((entry) {
            final i = entry.key;
            final ex = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PanelBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Exercise ${i + 1}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.danger, size: 20),
                          onPressed: () => setState(() {
                            draft.exercises.removeAt(i);
                            _updateEstimateIfNeeded();
                          }),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () async {
                        final selected = await showExercisePicker(context);
                        if (selected == null) return;
                        setState(() => ex.name = selected);
                      },
                      child: InputDecorator(
                        decoration: ironFieldDecoration(),
                        child: Row(
                          children: [
                            Expanded(child: Text(ex.name, style: const TextStyle(color: AppColors.text))),
                            const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sets', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              TextFormField(
                                key: ValueKey('sets_${ex.id}'),
                                initialValue: ex.sets.toString(),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppColors.text),
                                decoration: ironFieldDecoration(),
                                onChanged: (v) => setState(() {
                                  ex.sets = int.tryParse(v) ?? 1;
                                  _updateEstimateIfNeeded();
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Rest (sec)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              TextFormField(
                                key: ValueKey('rest_${ex.id}'),
                                initialValue: ex.restSeconds.toString(),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppColors.text),
                                decoration: ironFieldDecoration(),
                                onChanged: (v) => setState(() {
                                  ex.restSeconds = int.tryParse(v) ?? 0;
                                  _updateEstimateIfNeeded();
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          DashedButton(
            onPressed: () async {
              final selected = await showExercisePicker(context);
              if (selected == null) return;
              setState(() {
                draft.exercises.add(ExerciseTemplate(
                  id: 'e${DateTime.now().millisecondsSinceEpoch}',
                  name: selected,
                  sets: 3,
                  setSeconds: defaultSetSeconds,
                  restSeconds: 75,
                ));
                _updateEstimateIfNeeded();
              });
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.add, size: 16), SizedBox(width: 6), Text('Add exercise')],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            onPressed: () {
              app.saveTemplate(draft);
              app.goTo(app.editReturn);
            },
            child: const Text('Save workout'),
          ),
        ],
      ),
    );
  }
}
