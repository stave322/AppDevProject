import 'package:flutter/material.dart';

import '../store/store.dart';
import '../widgets/shared_widgets.dart';

const _library = <Map<String, dynamic>>[
  {
    'n': 'Push-ups',
    'm': 'Chest',
    'lvl': 'Beginner',
    's': 3,
    'r': 12,
    'rest': 45,
  },
  {
    'n': 'Dumbbell bench press',
    'm': 'Chest',
    'lvl': 'Intermediate',
    's': 3,
    'r': 10,
    'rest': 60,
  },
  {
    'n': 'Barbell bench press',
    'm': 'Chest',
    'lvl': 'Intermediate',
    's': 4,
    'r': 8,
    'rest': 90,
  },
  {
    'n': 'Dumbbell fly',
    'm': 'Chest',
    'lvl': 'Intermediate',
    's': 3,
    'r': 12,
    'rest': 60,
  },
  {
    'n': 'Lat pulldown',
    'm': 'Back',
    'lvl': 'Beginner',
    's': 3,
    'r': 12,
    'rest': 60,
  },
  {
    'n': 'Seated cable row',
    'm': 'Back',
    'lvl': 'Beginner',
    's': 3,
    'r': 12,
    'rest': 60,
  },
  {
    'n': 'Bent-over row',
    'm': 'Back',
    'lvl': 'Intermediate',
    's': 4,
    'r': 10,
    'rest': 75,
  },
  {'n': 'Pull-ups', 'm': 'Back', 'lvl': 'Advanced', 's': 4, 'r': 8, 'rest': 90},
  {
    'n': 'Bodyweight squat',
    'm': 'Legs',
    'lvl': 'Beginner',
    's': 3,
    'r': 15,
    'rest': 45,
  },
  {
    'n': 'Glute bridge',
    'm': 'Legs',
    'lvl': 'Beginner',
    's': 3,
    'r': 15,
    'rest': 45,
  },
  {'n': 'Lunges', 'm': 'Legs', 'lvl': 'Beginner', 's': 3, 'r': 12, 'rest': 60},
  {
    'n': 'Goblet squat',
    'm': 'Legs',
    'lvl': 'Intermediate',
    's': 3,
    'r': 12,
    'rest': 60,
  },
  {
    'n': 'Back squat',
    'm': 'Legs',
    'lvl': 'Intermediate',
    's': 4,
    'r': 8,
    'rest': 90,
  },
  {
    'n': 'Romanian deadlift',
    'm': 'Legs',
    'lvl': 'Intermediate',
    's': 3,
    'r': 10,
    'rest': 90,
  },
  {
    'n': 'Lateral raise',
    'm': 'Shoulders',
    'lvl': 'Beginner',
    's': 3,
    'r': 15,
    'rest': 45,
  },
  {
    'n': 'Face pull',
    'm': 'Shoulders',
    'lvl': 'Beginner',
    's': 3,
    'r': 15,
    'rest': 45,
  },
  {
    'n': 'Shoulder press',
    'm': 'Shoulders',
    'lvl': 'Intermediate',
    's': 3,
    'r': 10,
    'rest': 60,
  },
  {
    'n': 'Biceps curl',
    'm': 'Arms',
    'lvl': 'Beginner',
    's': 3,
    'r': 12,
    'rest': 45,
  },
  {
    'n': 'Triceps pushdown',
    'm': 'Arms',
    'lvl': 'Beginner',
    's': 3,
    'r': 15,
    'rest': 45,
  },
  {
    'n': 'Hammer curl',
    'm': 'Arms',
    'lvl': 'Beginner',
    's': 3,
    'r': 12,
    'rest': 45,
  },
  {'n': 'Plank', 'm': 'Core', 'lvl': 'Beginner', 's': 3, 'r': 30, 'rest': 30},
  {
    'n': 'Crunches',
    'm': 'Core',
    'lvl': 'Beginner',
    's': 3,
    'r': 20,
    'rest': 30,
  },
  {
    'n': 'Dead bug',
    'm': 'Core',
    'lvl': 'Beginner',
    's': 3,
    'r': 12,
    'rest': 30,
  },
  {
    'n': 'Russian twist',
    'm': 'Core',
    'lvl': 'Intermediate',
    's': 3,
    'r': 20,
    'rest': 30,
  },
  {
    'n': 'Jumping jacks',
    'm': 'Cardio',
    'lvl': 'Beginner',
    's': 3,
    'r': 40,
    'rest': 30,
  },
  {
    'n': 'High knees',
    'm': 'Cardio',
    'lvl': 'Beginner',
    's': 3,
    'r': 30,
    'rest': 30,
  },
  {
    'n': 'Mountain climbers',
    'm': 'Cardio',
    'lvl': 'Intermediate',
    's': 4,
    'r': 30,
    'rest': 30,
  },
  {
    'n': 'Burpees',
    'm': 'Cardio',
    'lvl': 'Intermediate',
    's': 4,
    'r': 12,
    'rest': 30,
  },
  {
    'n': 'Jump rope',
    'm': 'Cardio',
    'lvl': 'Intermediate',
    's': 4,
    'r': 60,
    'rest': 30,
  },
  {
    'n': 'Sprint intervals',
    'm': 'Cardio',
    'lvl': 'Advanced',
    's': 6,
    'r': 30,
    'rest': 60,
  },
];

class ExerciseLibraryScreen extends StatefulWidget {
  final String title;
  const ExerciseLibraryScreen({super.key, this.title = 'Choose exercises'});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  static const _levels = ['All', 'Beginner', 'Intermediate', 'Advanced'];
  static const _groups = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
  ];

  String _query = '';
  String _level = 'All';
  String _group = 'All';
  final Map<String, Map<String, dynamic>> _selected = {};
  final List<Map<String, dynamic>> _custom = [];

  Future<void> _addCustom() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CustomExerciseSheet(),
    );
    if (result == null || !mounted) return;
    final name = result['n'] as String;
    if (_library.any((exercise) => exercise['n'] == name) ||
        _custom.any((exercise) => exercise['n'] == name)) {
      snack(context, 'An exercise with that name already exists.');
      return;
    }

    setState(() {
      _custom.add(result);
      _selected[name] = result;
    });
  }

  Widget _filterChips(
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) => SizedBox(
    height: 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final option = options[index];
        final active = option == selected;
        return ChoiceChip(
          label: Text(option),
          selected: active,
          showCheckmark: false,
          selectedColor: primaryOf(context),
          labelStyle: TextStyle(
            color: active
                ? (isDark(context) ? kInk : Colors.white)
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => onSelected(option),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final exercises = [..._library, ..._custom]
        .where(
          (exercise) =>
              (_level == 'All' || exercise['lvl'] == _level) &&
              (_group == 'All' || exercise['m'] == _group) &&
              (exercise['n'] as String).toLowerCase().contains(
                _query.toLowerCase(),
              ),
        )
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kGapLg, kGapLg, kGapLg, 0),
              child: hdr(
                context,
                'Build your workout',
                widget.title,
                back: true,
                act: [
                  TextButton.icon(
                    onPressed: _addCustom,
                    icon: const Icon(Icons.add),
                    label: const Text('Custom'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kGapLg),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search exercises',
                ),
              ),
            ),
            const SizedBox(height: kGapMd),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kGapLg),
              child: _filterChips(
                _levels,
                _level,
                (value) => setState(() => _level = value),
              ),
            ),
            const SizedBox(height: kGapSm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kGapLg),
              child: _filterChips(
                _groups,
                _group,
                (value) => setState(() => _group = value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kGapLg, kGapMd, kGapLg, kGapSm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${exercises.length} exercises', style: muted),
              ),
            ),
            Expanded(
              child: exercises.isEmpty
                  ? const Center(
                      child: Text(
                        'No exercises match your search.',
                        style: muted,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(kGapLg, kGapXs, kGapLg, kGapMd),
                      children: [
                        for (final exercise in exercises)
                          _exerciseCard(exercise),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kGapLg, kGapSm, kGapLg, kGapMd),
          child: btn(
            _selected.isEmpty
                ? 'Choose exercises to continue'
                : 'Add ${_selected.length} exercise${_selected.length == 1 ? '' : 's'}',
            () {
              if (_selected.isEmpty) {
                snack(context, 'Choose at least one exercise.');
                return;
              }
              Navigator.pop(context, _selected.values.toList());
            },
          ),
        ),
      ),
    );
  }

  Widget _exerciseCard(Map<String, dynamic> exercise) {
    final name = exercise['n'] as String;
    final selected = _selected.containsKey(name);
    return card(
      color: selected ? tintOf(context) : null,
      onTap: () => setState(() {
        if (selected) {
          _selected.remove(name);
        } else {
          _selected[name] = Map<String, dynamic>.from(exercise);
        }
      }),
      pad: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: tintOf(context),
            child: Icon(
              Icons.fitness_center,
              color: primaryOf(context),
              size: 19,
            ),
          ),
          const SizedBox(width: kGapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: kGapXs),
                Text(
                  '${exercise['lvl']} · ${exercise['m']} · ${exercise['s']} × ${exercise['r']}',
                  style: muted,
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle : Icons.add_circle_outline,
            color: primaryOf(context),
          ),
        ],
      ),
    );
  }
}

class _CustomExerciseSheet extends StatefulWidget {
  const _CustomExerciseSheet();

  @override
  State<_CustomExerciseSheet> createState() => _CustomExerciseSheetState();
}

class _CustomExerciseSheetState extends State<_CustomExerciseSheet> {
  static const _groups = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
  ];
  static const _levels = ['Beginner', 'Intermediate', 'Advanced'];

  final _name = TextEditingController();
  final _sets = TextEditingController(text: '3');
  final _reps = TextEditingController(text: '10');
  final _rest = TextEditingController(text: '60');
  String _group = 'Chest';
  String _level = 'Beginner';

  @override
  void dispose() {
    _name.dispose();
    _sets.dispose();
    _reps.dispose();
    _rest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create your exercise',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: kGapXs),
            const Text('Add a move that fits your workout.', style: muted),
            const SizedBox(height: kGapLg),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Exercise name',
                hintText: 'e.g. Resistance band press',
                prefixIcon: Icon(Icons.fitness_center),
              ),
            ),
            const SizedBox(height: kGapMd),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _group,
                    decoration: const InputDecoration(
                      labelText: 'Muscle group',
                      prefixIcon: Icon(Icons.accessibility_new),
                    ),
                    items: [
                      for (final group in _groups)
                        DropdownMenuItem(value: group, child: Text(group)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _group = value);
                    },
                  ),
                ),
                const SizedBox(width: kGapMd),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _level,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      prefixIcon: Icon(Icons.signal_cellular_alt),
                    ),
                    items: [
                      for (final level in _levels)
                        DropdownMenuItem(value: level, child: Text(level)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _level = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: kGapMd),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    controller: _sets,
                    label: 'Sets',
                    icon: Icons.repeat,
                  ),
                ),
                const SizedBox(width: kGapMd),
                Expanded(
                  child: _numberField(
                    controller: _reps,
                    label: 'Reps / sec',
                    icon: Icons.fitness_center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kGapMd),
            _numberField(
              controller: _rest,
              label: 'Rest between sets (seconds)',
              icon: Icons.timer_outlined,
            ),
            const SizedBox(height: kGapLg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(kGapLg),
              decoration: BoxDecoration(
                color: tintOf(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: primaryOf(context)),
                  const SizedBox(width: kGapMd),
                  Expanded(
                    child: Text(
                      '${_sets.text} sets · ${_reps.text} reps/sec · $_level $_group',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: kGapLg),
            btn('Add custom exercise', _save),
          ],
        ),
      ),
    ),
  );

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  );

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      snack(context, 'Add an exercise name first.');
      return;
    }
    final sets = int.tryParse(_sets.text);
    final reps = int.tryParse(_reps.text);
    final rest = int.tryParse(_rest.text);
    if (sets == null ||
        sets < 1 ||
        reps == null ||
        reps < 1 ||
        rest == null ||
        rest < 0) {
      snack(context, 'Enter valid sets, reps and rest values.');
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'n': name,
      'm': _group,
      'lvl': _level,
      's': sets.clamp(1, 20),
      'r': reps.clamp(1, 300),
      'rest': rest.clamp(0, 600),
    });
  }
}
