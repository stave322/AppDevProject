import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fittract/screens/meal_picker_screen.dart';
import 'package:fittract/screens/routines_tab.dart';
import 'package:fittract/screens/workout_screen.dart';
import 'package:fittract/store/store.dart';

Map<String, dynamic> routine({
  String id = 'r-push',
  String name = 'Push Day',
  num rest = 45,
}) => {
  'id': id,
  'name': name,
  'type': 'Strength',
  'ex': <Map<String, dynamic>>[
    {
      'n': 'Bench Press',
      'm': 'Chest · barbell',
      's': 3,
      'r': 8,
      'rest': rest,
    },
    {'n': 'Squat', 'm': 'Legs · barbell', 's': 2, 'r': 5, 'rest': 0},
  ],
};

Map<String, dynamic> savedSession({
  String rid = 'r-push',
  String name = 'Push Day',
  bool valid = true,
}) => {
  'rid': rid,
  'name': name,
  'i': valid ? 1 : 'not-a-number',
  'secs': valid ? 65 : null,
  'done': valid ? <bool>[true, false] : 'garbage',
  'sets': valid
      ? <List<Map<String, dynamic>>>[
          [
            {'kg': 40, 'rp': 8, 'ok': true},
            {'kg': 45, 'rp': 8, 'ok': true},
            {'kg': 50, 'rp': 8, 'ok': true},
          ],
          [
            {'kg': 60, 'rp': 5, 'ok': false},
            {'kg': 60, 'rp': 5, 'ok': false},
          ],
        ]
      : {'oops': true},
  'restLeft': 0,
  'restTotal': 0,
  'restAfter': '',
};

Future<void> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  await store.init();
}

/// Hosts [page] on top of a still-mounted home route so back navigation has
/// somewhere to return to. The fake clock only advances by a fraction of a
/// second so the workout's 1 Hz timer has not ticked when the helper returns.
Future<void> pushScreen(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1100, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: Center(child: Text('HOME')))),
  );
  final home = tester.element(find.text('HOME'));
  Navigator.of(home).push(MaterialPageRoute<void>(builder: (_) => page)).ignore();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> settleDialogs(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> tapBtn(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pump();
  await tester.tap(find.text(label));
}

/// ScaffoldMessenger renders a raised snackbar on every mounted [Scaffold],
/// so scope the expectation to the screen that raised it.
Finder messageOn(Finder screen, String message) =>
    find.descendant(of: screen, matching: find.text(message));

void main() {
  testWidgets('Rest countdown starts with the configured rest value', (
    tester,
  ) async {
    await freshStore();
    await pushScreen(tester, WorkoutScreen(routine()));

    expect(find.text('REST'), findsNothing);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(find.text('REST'), findsOneWidget);
    expect(find.text('00:45'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('00:42'), findsOneWidget);
  });

  testWidgets('Skip rest ends the countdown and clears the saved rest state', (
    tester,
  ) async {
    await freshStore();
    await pushScreen(tester, WorkoutScreen(routine()));

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('REST'), findsOneWidget);

    await tester.tap(find.text('Skip rest'));
    await tester.pump();

    expect(find.text('REST'), findsNothing);
    expect((store.d['activeW'] as Map)['restLeft'], 0);
  });

  testWidgets('Elapsed timer keeps running after the rest is skipped', (
    tester,
  ) async {
    await freshStore();
    await pushScreen(tester, WorkoutScreen(routine()));

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.tap(find.text('Skip rest'));
    await tester.pump();

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('00:04'), findsOneWidget);
    expect(find.text('REST'), findsNothing);
  });

  testWidgets('Saved state for the same routine is recovered', (tester) async {
    await freshStore();
    store.d['activeW'] = savedSession();

    await pushScreen(tester, WorkoutScreen(routine()));

    expect(
      messageOn(find.byType(WorkoutScreen), 'Resumed your saved session.'),
      findsOneWidget,
    );
    expect(find.text('01:05'), findsOneWidget);
    expect(find.text('1 of 2 exercises complete'), findsOneWidget);
    final restoredKg = find.descendant(
      of: find.byKey(const ValueKey('kg10')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(restoredKg).controller.text, '60');
    expect((store.d['activeW'] as Map)['i'], 1);
  });

  testWidgets('Malformed saved workout state does not crash', (tester) async {
    await freshStore();
    store.d['activeW'] = savedSession(valid: false);

    await pushScreen(tester, WorkoutScreen(routine()));

    expect(tester.takeException(), isNull);
    expect(find.text('0 of 2 exercises complete'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('⚑ Finish workout'), findsOneWidget);
  });

  testWidgets('Back navigation asks first and Cancel keeps the screen open', (
    tester,
  ) async {
    await freshStore();
    await pushScreen(tester, WorkoutScreen(routine()));

    await Navigator.maybePop(tester.element(find.byType(WorkoutScreen)));
    await settleDialogs(tester);

    expect(find.text('Leave this workout? Your progress stays saved.'),
        findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await settleDialogs(tester);

    expect(find.byType(WorkoutScreen), findsOneWidget);
    expect(store.d.containsKey('activeW'), isTrue);
  });

  testWidgets('Confirmed back navigation exits once and keeps progress', (
    tester,
  ) async {
    await freshStore();
    await pushScreen(tester, WorkoutScreen(routine()));

    await Navigator.maybePop(tester.element(find.byType(WorkoutScreen)));
    await settleDialogs(tester);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutScreen), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
    expect(store.d.containsKey('activeW'), isTrue);
    expect(store.hist, isEmpty);
  });

  testWidgets('A saved session for another routine is confirmed before it is '
      'replaced', (tester) async {
    await freshStore();
    store.d['activeW'] = savedSession(rid: 'r-legs', name: 'Leg Day');

    await pushScreen(tester, WorkoutScreen(routine()));
    await tester.pumpAndSettle();

    expect(
      find.text('Discard the saved session for Leg Day?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutScreen), findsNothing);
    expect((store.d['activeW'] as Map)['rid'], 'r-legs');
  });

  testWidgets('Discarding another routine session replaces it without a '
      'duplicate save', (tester) async {
    await freshStore();
    store.d['activeW'] = savedSession(rid: 'r-legs', name: 'Leg Day');

    await pushScreen(tester, WorkoutScreen(routine()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutScreen), findsOneWidget);
    expect((store.d['activeW'] as Map)['rid'], 'r-push');
    expect(store.hist, isEmpty);
  });

  testWidgets('Invalid set load cannot be marked complete', (tester) async {
    await freshStore();
    await pushScreen(tester, WorkoutScreen(routine()));

    await tester.enterText(find.byKey(const ValueKey('kg00')), '9999');
    await tester.pump();
    await tester.tap(find.text('✓ Mark exercise complete'));
    await tester.pump();

    expect(
      messageOn(find.byType(WorkoutScreen), 'Weight must be between 0 and 500 kg.'),
      findsOneWidget,
    );
    expect(find.text('0 of 2 exercises complete'), findsOneWidget);
    expect((store.d['activeW'] as Map)['done'], <bool>[false, false]);

    // Empty input falls back to a zero load, which stays valid.
    await tester.enterText(find.byKey(const ValueKey('kg00')), '');
    await tester.pump();
    await tester.tap(find.text('✓ Mark exercise complete'));
    await tester.pump();

    expect(find.text('1 of 2 exercises complete'), findsOneWidget);
    expect((store.d['activeW'] as Map)['done'], <bool>[true, false]);
    expect(find.text('REST'), findsOneWidget);
  });

  testWidgets('Invalid set load blocks finishing until it is corrected', (
    tester,
  ) async {
    await freshStore();
    await pushScreen(tester, WorkoutScreen(routine()));

    await tester.enterText(find.byKey(const ValueKey('rp00')), '9999');
    await tester.pump();
    await tapBtn(tester, '⚑ Finish workout');
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutScreen), findsOneWidget);
    expect(
      messageOn(find.byType(WorkoutScreen), 'Reps must be between 1 and 300.'),
      findsOneWidget,
    );
    expect(store.hist, isEmpty);
    expect(store.d.containsKey('activeW'), isTrue);

    await tester.enterText(find.byKey(const ValueKey('rp00')), '8');
    await tester.pump();
    // Complete an exercise: finishing is refused while nothing is done.
    await tester.tap(find.text('✓ Mark exercise complete'));
    await tester.pump();
    await tapBtn(tester, '⚑ Finish workout');
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutScreen), findsNothing);
    expect(store.hist, hasLength(1));
  });

  testWidgets('Finishing with no completed exercise is refused', (
    tester,
  ) async {
    await freshStore();
    await pushScreen(tester, WorkoutScreen(routine()));

    await tapBtn(tester, '⚑ Finish workout');
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutScreen), findsOneWidget);
    expect(
      messageOn(
        find.byType(WorkoutScreen),
        'Complete at least one exercise before finishing.',
      ),
      findsOneWidget,
    );
    expect(store.hist, isEmpty);
    expect(store.d.containsKey('activeW'), isTrue);
  });

  testWidgets('Finishing records history and clears the active snapshot', (
    tester,
  ) async {
    await freshStore();
    await pushScreen(tester, WorkoutScreen(routine()));

    // Complete at least one exercise so the workout passes validation.
    await tester.tap(find.text('✓ Mark exercise complete'));
    await tester.pump();
    await tapBtn(tester, '⚑ Finish workout');
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutScreen), findsNothing);
    expect(find.text('Workout saved! 💪'), findsOneWidget);
    expect(store.d.containsKey('activeW'), isFalse);
    expect(store.hist, hasLength(1));
    expect(store.hist.single['n'], 'Push Day');
    expect(store.hist.single['min'], 1);
    expect(store.hist.single['ex'], 1);
  });

  testWidgets('Discarding clears the snapshot without recording a workout', (
    tester,
  ) async {
    await freshStore();
    await pushScreen(tester, WorkoutScreen(routine()));

    await tapBtn(tester, 'Discard session');
    await settleDialogs(tester);
    expect(find.text('Discard this session?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutScreen), findsNothing);
    expect(store.d.containsKey('activeW'), isFalse);
    expect(store.hist, isEmpty);
  });

  const invalidConfigs = <Map<String, Object?>>[
    {
      'label': 'sets',
      's': 99,
      'r': 8,
      'rest': 60,
      'message': 'Bench Press: Sets must be between 1 and 20.',
    },
    {
      'label': 'reps',
      's': 3,
      'r': 0,
      'rest': 60,
      'message': 'Bench Press: Reps must be between 1 and 300.',
    },
    {
      'label': 'rest',
      's': 3,
      'r': 8,
      'rest': 900,
      'message': 'Bench Press: Rest must be between 0 and 600 seconds.',
    },
  ];

  for (final c in invalidConfigs) {
    testWidgets(
      'Edit routine rejects out-of-range ${c['label']} and stays open',
      (tester) async {
        await freshStore();
        await pushScreen(
          tester,
          EditRoutine(<String, dynamic>{
            'id': 'r-x',
            'name': 'Bad Routine',
            'type': 'Strength',
            'ex': [
              {
                'n': 'Bench Press',
                'm': 'Chest · barbell',
                's': c['s'],
                'r': c['r'],
                'rest': c['rest'],
              },
            ],
          }),
        );

        await tapBtn(tester, '✓ Save routine');
        await tester.pump();

        expect(
          messageOn(find.byType(EditRoutine), c['message'] as String),
          findsOneWidget,
        );
        expect(find.byType(EditRoutine), findsOneWidget);
        expect(store.routines, isEmpty);
      },
    );
  }

  testWidgets('Edit routine saves a valid configuration', (tester) async {
    await freshStore();
    await pushScreen(
      tester,
      EditRoutine(<String, dynamic>{
        'id': 'r-x',
        'name': 'Good Routine',
        'type': 'Strength',
        'ex': [
          {'n': 'Bench Press', 'm': 'Chest · barbell', 's': 3, 'r': 8, 'rest': 60},
        ],
      }),
    );

    await tapBtn(tester, '✓ Save routine');
    await tester.pumpAndSettle();

    expect(find.byType(EditRoutine), findsNothing);
    expect(store.routines, hasLength(1));
    final saved = store.routines.single as Map;
    final ex = (saved['ex'] as List).single as Map;
    expect(ex['s'], 3);
    expect(ex['r'], 8);
    expect(ex['rest'], 60);
  });

  testWidgets('Manual meal feedback is raised before the screen closes', (
    tester,
  ) async {
    await freshStore();
    store.meals.clear();

    await pushScreen(tester, const ManualMealScreen());

    await tester.enterText(find.byType(TextField).at(0), 'Test Bowl');
    await tester.enterText(find.byType(TextField).at(2), '320');
    await tapBtn(tester, 'Add to food log');
    await tester.pumpAndSettle();

    expect(store.meals, hasLength(1));
    expect(store.meals.single['n'], 'Test Bowl');
    expect(find.byType(ManualMealScreen), findsNothing);
    expect(find.text('Test Bowl added to today.'), findsOneWidget);
  });
}
