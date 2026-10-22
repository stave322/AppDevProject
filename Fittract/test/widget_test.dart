import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittract/main.dart';
import 'package:fittract/screens/food_screen.dart';
import 'package:fittract/screens/profile_tab.dart';
import 'package:fittract/screens/today_tab.dart';
import 'package:fittract/screens/weight_screen.dart';
import 'package:fittract/store/store.dart';
import 'package:fittract/widgets/shared_widgets.dart';

void _ignoreTab(int _) {}

void main() {
  test('New account data starts empty', () {
    final freshStore = Store()..d = Store().seed();

    expect(freshStore.routines, isEmpty);
    expect(freshStore.sch, isEmpty);
    expect(freshStore.meals, isEmpty);
    expect(freshStore.acts, isEmpty);
    expect(freshStore.hist, isEmpty);
    expect(freshStore.d['weights'], isEmpty);
    expect(freshStore.steps, 0);
    expect(freshStore.lastW(), 0);
    expect(freshStore.goalProgress(), 0);
    expect(freshStore.d['age'], isNull);
    expect(freshStore.d['h'], isNull);
  });

  test('Workout reminders cover every workout today, in time order', () {
    final s = Store()..d = Store().seed();
    s.d['routines'] = [
      {'id': 1, 'name': 'Push day', 'ex': <dynamic>[]},
    ];
    s.d['sch'] = [
      // Deliberately out of order: the reminder list must sort by time.
      {'id': 1, 'r': 1, 'd': today(), 't': '18:00'},
      {'id': 2, 'r': 1, 'd': today(), 't': '07:30'},
      {'id': 3, 'r': 1, 'd': daysAgo(1), 't': '09:00'}, // yesterday
      {'id': 4, 'r': 1, 'd': daysAgo(-1), 't': '09:00'}, // tomorrow
    ];

    final workoutNotes = s.notes().where((n) => n[0] == '🏋').toList();
    expect(workoutNotes, hasLength(2));
    expect(workoutNotes[0][1], 'Workout at 07:30');
    expect(workoutNotes[0][2], 'Push day');
    expect(workoutNotes[1][1], 'Workout at 18:00');
    expect(workoutNotes[1][2], 'Push day');

    // Deleting a schedule entry removes its reminder immediately.
    s.sch.removeWhere((e) => e['id'] == 2);
    final afterDelete = s.notes().where((n) => n[0] == '🏋').toList();
    expect(afterDelete, hasLength(1));
    expect(afterDelete.single[1], 'Workout at 18:00');

    // The workout-reminder toggle hides them.
    s.d['wr'] = false;
    expect(s.notes().where((n) => n[0] == '🏋'), isEmpty);
    s.d['wr'] = true;

    // A deleted routine falls back to a generic name instead of crashing.
    s.d['routines'] = <Map<String, dynamic>>[];
    final fallback = s.notes().where((n) => n[0] == '🏋').toList();
    expect(fallback.single[2], 'Workout');
  });

  test('next() returns the earliest upcoming workout', () {
    final s = Store()..d = Store().seed();
    s.d['sch'] = [
      {'id': 1, 'r': 1, 'd': daysAgo(-2), 't': '18:00'}, // two days ahead
      {'id': 2, 'r': 1, 'd': today(), 't': '18:00'},
      {'id': 3, 'r': 1, 'd': today(), 't': '07:30'},
    ];
    expect(s.next()?['t'], '07:30');
    expect(s.next()?['d'], today());

    s.sch.removeWhere((e) => e['d'] == today());
    expect(s.next()?['d'], daysAgo(-2));

    s.d['sch'] = <Map<String, dynamic>>[];
    expect(s.next(), isNull);
  });

  test('Google accounts keep separate local fitness data', () async {
    SharedPreferences.setMockInitialValues({});
    final accountStore = Store();
    await accountStore.init();

    accountStore.activateGoogleAccount(
      uid: 'first-user',
      email: 'first@example.com',
      displayName: 'First User',
    );
    accountStore.d['steps'] = 1200;
    accountStore.save();

    accountStore.activateGoogleAccount(
      uid: 'second-user',
      email: 'second@example.com',
      displayName: 'Second User',
    );
    expect(accountStore.steps, 0);

    accountStore.activateGoogleAccount(
      uid: 'first-user',
      email: 'first@example.com',
      displayName: 'First User',
    );
    expect(accountStore.steps, 1200);
  });

  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.byType(App), findsOneWidget);
  });

  testWidgets('Screen navigation uses an animated route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: btn(
              'Open screen',
              () => go(
                context,
                const Scaffold(body: Center(child: Text('Destination'))),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open screen'));
    await tester.pumpAndSettle();

    final destination = tester.element(find.text('Destination'));
    expect(ModalRoute.of(destination), isA<PageRouteBuilder<void>>());
  });

  testWidgets('Shared buttons animate when pressed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: btn('Press me', () {}))),
    );

    final button = find.text('Press me');
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump();

    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, .97);

    await tester.pump(const Duration(milliseconds: 120));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('Dark mode setting updates the app theme', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await tester.pumpWidget(const App());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);

    store.toggle('dark');
    await tester.pumpAndSettle();

    final darkApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(darkApp.themeMode, ThemeMode.dark);
  });

  testWidgets('Profile offers a designed photo placeholder and detail editor', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.d['user'] = 'profile@example.com';
    store.d['name'] = 'FitTrack User';
    store.save();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileTab())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add profile photo'), findsOneWidget);
    final editButton = find.textContaining('Edit personal details');
    await tester.ensureVisible(editButton);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    expect(find.text('Personal details'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Weight'), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).last, '70.5');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(store.lastW(), 70.5);
    expect(store.d['weights'].single[0], today());
  });

  testWidgets('Profile camera icon can be pressed without opening anything', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileTab())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.camera_alt_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('Today notifications show enabled workout and meal reminders', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.d['wr'] = true;
    store.d['mr'] = true;
    store.d['routines'] = [
      {
        'id': 1,
        'name': 'Morning workout',
        'type': 'Strength',
        'ex': <Map<String, dynamic>>[],
      },
    ];
    store.d['sch'] = [
      {'id': 1, 'r': 1, 'd': today(), 't': '08:00'},
    ];
    store.save();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TodayTab(goTo: _ignoreTab)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();

    expect(find.text('Workout at 08:00'), findsOneWidget);
    expect(find.text('Meal reminder'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Morning workout'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Weight tracker logs weight and saves redesigned goals', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WeightScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text("Log today's weight"), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Weight goals'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Weight goals'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Your weight'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField).first, '68.4');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save weight'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save weight'));
    await tester.pumpAndSettle();
    expect(store.lastW(), 68.4);

    await tester.scrollUntilVisible(
      find.text('Target weight'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField).at(1), '72');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save goals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save goals'));
    await tester.pumpAndSettle();
    expect(store.goal['w'], 72.0);
  });

  testWidgets('Food screen offers preset and manual meal logging', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.meals.clear();

    await tester.pumpWidget(const MaterialApp(home: FoodScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('+  Log food'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('+  Log food'));
    await tester.pumpAndSettle();
    expect(find.text('Ready-made meals'), findsOneWidget);
    expect(find.text('Oatmeal with berries'), findsOneWidget);
    expect(
      find.text('Rolled oats with milk, blueberries, and a spoonful of honey.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Oatmeal with berries'));
    final addPreset = find.ancestor(
      of: find.text('Add to today').first,
      matching: find.byType(FilledButton),
    );
    await tester.tap(addPreset);
    await tester.pumpAndSettle();
    expect(store.meals, hasLength(1));
    expect(store.meals.first['k'], 320);
    expect(store.meals.first['desc'], contains('blueberries'));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('＋  Add food manually'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('＋  Add food manually'));
    await tester.pumpAndSettle();
    expect(find.text('Meal details'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Homemade soup');
    await tester.enterText(find.byType(TextField).at(1), 'Tomato and lentil');
    await tester.enterText(find.byType(TextField).at(2), '240');
    await tester.enterText(find.byType(TextField).at(3), '14');
    await tester.enterText(find.byType(TextField).at(4), '32');
    await tester.enterText(find.byType(TextField).at(5), '5');
    FocusManager.instance.primaryFocus?.unfocus();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Add to food log'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to food log'));
    await tester.pumpAndSettle();

    expect(store.meals, hasLength(2));
    expect(store.meals.last['n'], 'Homemade soup');
    expect(store.meals.last['desc'], 'Tomato and lentil');
    expect(store.meals.last['k'], 240);
    expect(store.kcal(), 560);
  });

  testWidgets('Daily nutrition goals can be edited and are persisted', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();

    await tester.pumpWidget(const MaterialApp(home: FoodScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Edit goals'));
    await tester.tap(find.text('Edit goals'));
    await tester.pumpAndSettle();
    expect(find.text('Daily nutrition goals'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '2300');
    await tester.enterText(find.byType(TextField).at(1), '160');
    await tester.enterText(find.byType(TextField).at(2), '240');
    await tester.enterText(find.byType(TextField).at(3), '70');
    await tester.tap(find.text('Save nutrition goals'));
    await tester.pumpAndSettle();

    expect(store.nutritionGoals['calories'], 2300);
    expect(store.nutritionGoals['protein'], 160);
    expect(store.nutritionGoals['carbs'], 240);
    expect(store.nutritionGoals['fat'], 70);
    expect(find.text('Daily goal · 2300 kcal'), findsOneWidget);
    expect(find.text('0 / 160 g'), findsOneWidget);
  });
}
