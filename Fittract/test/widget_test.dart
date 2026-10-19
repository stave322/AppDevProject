import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittract/main.dart';
import 'package:fittract/store/store.dart';
import 'package:fittract/widgets/shared_widgets.dart';

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
}
