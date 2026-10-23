import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fittract/main.dart';
import 'package:fittract/store/store.dart';

void main() {
  /// Hashing runs in a real isolate. Yield one frame first — that is what
  /// lets the submit handler pass its end-of-frame barrier and start hashing
  /// with the spinner painted — then give the isolate real time before
  /// resuming the fake-async pump loop.
  Future<void> settleHashing(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  /// Creates an account through the registration form and waits for the
  /// flow to finish (it ends back on the Login screen).
  Future<void> registerThroughForm(
    WidgetTester tester, {
    String email = 'reg@example.com',
  }) async {
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Test User');
    await tester.enterText(find.byType(TextField).at(1), email);
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.enterText(find.byType(TextField).at(3), 'password123');
    await tester.tap(
      find.text('I agree to the Terms of Service and Privacy Policy.'),
    );
    await tester.pump();

    await tester.tap(find.text('Create account'));
    await settleHashing(tester);
  }

  testWidgets('Registration paints the busy spinner before hashing, then returns to Login', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    pbkdf2IterationsOverride = 1000;
    await store.init();
    addTearDown(() => pbkdf2IterationsOverride = 0);

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Test User');
    await tester.enterText(find.byType(TextField).at(1), 'reg@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.enterText(find.byType(TextField).at(3), 'password123');
    await tester.tap(
      find.text('I agree to the Terms of Service and Privacy Policy.'),
    );
    await tester.pump();

    await tester.tap(find.text('Create account'));
    // One frame after the tap, the busy spinner must already be on screen —
    // it paints before the (potentially blocking) password hashing starts.
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Create account'), findsNothing);

    // Hashing runs in a real isolate, so give it real time to finish before
    // resuming the fake-async test pump loop.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    // Registration must never authenticate the app: the flow ends back on
    // the Login form, with a success note, and never on the dashboard.
    expect(store.hasActiveSession, isFalse);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Create your account'), findsNothing);
    expect(
      find.text('Account created successfully. Please log in.'),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Duplicate-email failure resets the Create account button', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      // Account already exists: register short-circuits before hashing.
      emailStorageKey('taken@b.com'): jsonEncode({
        'user': 'taken@b.com',
        'name': 'Taken',
        'cred': <String, dynamic>{
          'alg': 'pbkdf2-hmac-sha256',
          'salt': 'AA==',
          'hash': 'AA==',
          'iters': 1000,
        },
      }),
    });
    await store.init();

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Test User');
    await tester.enterText(find.byType(TextField).at(1), 'taken@b.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.enterText(find.byType(TextField).at(3), 'password123');
    await tester.tap(
      find.text('I agree to the Terms of Service and Privacy Policy.'),
    );
    await tester.pump();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    // Busy state cleared and the failure surfaced instead of a stuck spinner.
    expect(find.text('Create account'), findsOneWidget);
    expect(
      find.text('An account with that email already exists.'),
      findsOneWidget,
    );
    // A failed registration never shows the success note.
    expect(
      find.text('Account created successfully. Please log in.'),
      findsNothing,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(store.hasActiveSession, isFalse);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Hashing exception resets the Log in button with a message', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      // Valid JSON but a salt that is not base64: verification throws,
      // which is the path the busy-state catch is there for.
      emailStorageKey('bad@b.com'): jsonEncode({
        'user': 'bad@b.com',
        'cred': <String, dynamic>{
          'alg': 'pbkdf2-hmac-sha256',
          'salt': '@@@not-base64@@@',
          'hash': 'AA==',
          'iters': 1000,
        },
      }),
    });
    await store.init();

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'bad@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(store.hasActiveSession, isFalse);
  });

  testWidgets('A cloud sign-in that never answers clears the busy state and reports it', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    pbkdf2IterationsOverride = 1000;
    await store.init();
    addTearDown(() {
      pbkdf2IterationsOverride = 0;
      store.cloudLinkOverride = null;
      store.cloudLinkTimeout = const Duration(seconds: 15);
    });

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    // Create the account first, so the login below reaches the cloud step
    // with a correct local password.
    await registerThroughForm(tester);

    store.cloudLinkTimeout = const Duration(milliseconds: 500);
    store.cloudLinkOverride =
        ({required String email, required String password}) =>
            Completer<String?>().future;

    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Log in'));
    await settleHashing(tester);

    // The bounded wait ends: no spinner left behind, the button is usable
    // again, and the reason is on screen in the store's own words.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Log in'), findsOneWidget);
    expect(
      find.text(
        'Could not reach the account service. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(store.hasActiveSession, isFalse);
    expect(store.sessionUid, isNull);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Login password field toggles visibility without losing text', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    final pwField = find.byType(TextField).at(1); // email, password
    await tester.enterText(pwField, 'secret123');
    expect(tester.widget<TextField>(pwField).obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(pwField).obscureText, isFalse);
    expect(tester.widget<TextField>(pwField).controller!.text, 'secret123');
    expect(find.byTooltip('Hide password'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(tester.widget<TextField>(pwField).obscureText, isTrue);
    expect(tester.widget<TextField>(pwField).controller!.text, 'secret123');
  });

  testWidgets('Register password and confirm-password toggles are independent', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    final pwField = find.byType(TextField).at(2); // name, email, password
    final pw2Field = find.byType(TextField).at(3);
    await tester.enterText(pwField, 'password123');
    await tester.enterText(pw2Field, 'password123');

    expect(tester.widget<TextField>(pwField).obscureText, isTrue);
    expect(tester.widget<TextField>(pw2Field).obscureText, isTrue);

    // Both fields offer "Show password"; reveal only the password field.
    await tester.tap(find.byTooltip('Show password').first);
    await tester.pump();
    expect(tester.widget<TextField>(pwField).obscureText, isFalse);
    expect(tester.widget<TextField>(pw2Field).obscureText, isTrue);
    expect(tester.widget<TextField>(pwField).controller!.text, 'password123');
    expect(tester.widget<TextField>(pw2Field).controller!.text, 'password123');

    // The remaining "Show password" belongs to the confirm field.
    await tester.tap(find.byTooltip('Show password').first);
    await tester.pump();
    expect(tester.widget<TextField>(pw2Field).obscureText, isFalse);

    // Hide the password field again; confirm stays visible.
    await tester.tap(find.byTooltip('Hide password').first);
    await tester.pump();
    expect(tester.widget<TextField>(pwField).obscureText, isTrue);
    expect(tester.widget<TextField>(pw2Field).obscureText, isFalse);
    expect(tester.widget<TextField>(pw2Field).controller!.text, 'password123');
  });

  testWidgets('A registered account signs in manually and reaches the dashboard', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    pbkdf2IterationsOverride = 1000;
    await store.init();
    addTearDown(() => pbkdf2IterationsOverride = 0);

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    await registerThroughForm(tester);

    // The flow ended back on Login: still signed out, dashboard not shown.
    expect(store.hasActiveSession, isFalse);
    expect(find.byType(NavigationBar), findsNothing);

    // The email stays filled in; only the password has to be typed again.
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Log in'));
    await settleHashing(tester);

    // A separate, successful login is what authenticates and opens the app.
    expect(store.hasActiveSession, isTrue);
    expect(store.d['user'], 'reg@example.com');
    expect(store.d['name'], 'Test User');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.text('Account created successfully. Please log in.'),
      findsNothing,
    );
  });

  testWidgets('Session cleanup after registration keeps the account and its profile', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    pbkdf2IterationsOverride = 1000;
    await store.init();
    addTearDown(() => pbkdf2IterationsOverride = 0);

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    await registerThroughForm(tester);

    // Nothing that a restart (or an auth-state listener) could treat as a
    // signed-in state survives the registration cleanup...
    expect(store.hasActiveSession, isFalse);
    expect(store.sp.getString('ft_session_meta'), isNull);
    expect(store.d['user'], isNull);

    // ...while the account itself and everything registration initialized
    // are kept in its own bucket.
    final raw = store.sp.getString(emailStorageKey('reg@example.com'));
    expect(raw, isNotNull);
    final decoded = jsonDecode(raw!) as Map<String, dynamic>;
    expect(decoded['user'], 'reg@example.com');
    expect(decoded['name'], 'Test User');
    expect(decoded['cred'], isA<Map>());

    // A restart stays signed out and the account is still there.
    await store.init();
    expect(store.hasActiveSession, isFalse);
    expect(store.sp.getString(emailStorageKey('reg@example.com')), raw);

    // Signing in manually restores that same profile.
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Log in'));
    await settleHashing(tester);

    expect(store.hasActiveSession, isTrue);
    expect(store.d['user'], 'reg@example.com');
    expect(store.d['name'], 'Test User');
  });

  testWidgets('An unexpected Google sign-in failure shows a safe message and clears busy', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Under test no Firebase/Google SDK answers the plugin channel, so the
    // attempt fails with an unexpected PlatformException — the class of
    // error the catch-all fallback exists to absorb.
    await tester.tap(find.text('Continue with Google'));
    // One frame after the tap the busy spinner must already paint, before
    // the async failure arrives.
    await tester.pump();

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    // Busy state always clears: no spinner left behind and the button works.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);

    // A short, mapped message is shown instead of silence...
    expect(
      find.text('Google sign-in failed. Please try again.'),
      findsOneWidget,
    );
    // ...and no raw error details, channel names or config text leak out.
    final visible = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join('\n');
    expect(visible.contains('PlatformException'), isFalse);
    expect(visible.contains('channel-error'), isFalse);
    expect(visible.toLowerCase().contains('pigeon'), isFalse);

    // The failure never authenticates or syncs anything.
    expect(store.hasActiveSession, isFalse);
    expect(store.sessionUid, isNull);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
