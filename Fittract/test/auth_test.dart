import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fittract/store/store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Keep hashing fast in tests; production uses 210k iterations.
    pbkdf2IterationsOverride = 1000;
  });

  tearDown(() {
    pbkdf2IterationsOverride = 0;
  });

  Future<Store> freshStore() async {
    final s = Store();
    await s.init();
    return s;
  }

  String rawAccount(Store s, String email) =>
      s.sp.getString(emailStorageKey(normalizeEmail(email)))!;

  test('register creates a hashed per-account snapshot but no session', () async {
    final s = await freshStore();

    final result = await s.register(
      name: 'Ada Lovelace',
      email: '  Ada@Example.COM ',
      password: 'correct horse',
    );

    expect(result, AuthResult.success);
    // Registration must not authenticate the app: the user is sent back to
    // the Login screen and signs in separately.
    expect(s.hasActiveSession, isFalse);
    expect(s.isEmailAccount, isFalse);
    expect(s.d['user'], isNull);

    final raw = rawAccount(s, 'ada@example.com');
    expect(raw, isNot(contains('correct horse')));
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    expect(decoded['user'], 'ada@example.com');
    expect(decoded['name'], 'Ada Lovelace');
    expect(decoded['cred']['alg'], 'pbkdf2-hmac-sha256');
    expect(decoded['cred']['iters'], 1000);
    expect(decoded.containsKey('pw'), isFalse);

    // A separate, successful login is what authenticates the session, and it
    // brings the freshly created profile back with it.
    expect(
      await s.login(email: 'ada@example.com', password: 'correct horse'),
      AuthResult.success,
    );
    expect(s.hasActiveSession, isTrue);
    expect(s.isEmailAccount, isTrue);
    expect(s.d['user'], 'ada@example.com');
    expect(s.d['name'], 'Ada Lovelace');
  });

  test('registration cleanup keeps the account and leaves nothing signed in',
      () async {
    final s = await freshStore();
    await s.register(name: 'Ada', email: 'ada@b.com', password: 'password1');

    // Session teardown: no active session, no cloud identity, no pending
    // sync work, and no session pointer a restart could resume from.
    expect(s.hasActiveSession, isFalse);
    expect(s.sessionUid, isNull);
    expect(s.syncRunning, isFalse);
    expect(s.syncPending, isFalse);
    expect(s.sp.getString('ft_session_meta'), isNull);

    // The cleanup never deletes the account or its initialized profile.
    final next = await freshStore();
    expect(next.hasActiveSession, isFalse);
    final decoded =
        jsonDecode(rawAccount(next, 'ada@b.com')) as Map<String, dynamic>;
    expect(decoded['user'], 'ada@b.com');
    expect(decoded['name'], 'Ada');
    expect(decoded['cred'], isA<Map>());

    // ...and that account still signs in with everything it started with.
    expect(
      await next.login(email: 'ada@b.com', password: 'password1'),
      AuthResult.success,
    );
    expect(next.hasActiveSession, isTrue);
    expect(next.d['name'], 'Ada');
    expect(next.d['user'], 'ada@b.com');
  });

  test('register validates input and rejects duplicates', () async {
    final s = await freshStore();

    expect(
      await s.register(name: '', email: 'a@b.com', password: 'password1'),
      AuthResult.invalidInput,
    );
    expect(
      await s.register(name: 'A', email: 'not-an-email', password: 'password1'),
      AuthResult.invalidInput,
    );
    expect(
      await s.register(name: 'A', email: 'a@b.com', password: 'short'),
      AuthResult.invalidInput,
    );

    expect(
      await s.register(name: 'A', email: 'a@b.com', password: 'password1'),
      AuthResult.success,
    );
    expect(
      await s.register(name: 'B', email: 'A@B.COM', password: 'password2'),
      AuthResult.duplicateEmail,
    );
  });

  test('login verifies the password and rejects wrong ones', () async {
    final s = await freshStore();
    await s.register(name: 'A', email: 'a@b.com', password: 'password1');
    s.signOut();

    expect(s.hasActiveSession, isFalse);
    expect(
      await s.login(email: 'a@b.com', password: 'wrong-pass'),
      AuthResult.wrongPassword,
    );
    expect(
      await s.login(email: 'missing@b.com', password: 'password1'),
      AuthResult.unknownEmail,
    );
    expect(
      await s.login(email: 'a@b.com', password: 'password1'),
      AuthResult.success,
    );
    expect(s.hasActiveSession, isTrue);
    expect(s.d['user'], 'a@b.com');
    expect(s.d['name'], 'A');
  });

  test('sign out preserves account data for the next login', () async {
    final s = await freshStore();
    await s.register(name: 'A', email: 'a@b.com', password: 'password1');
    await s.login(email: 'a@b.com', password: 'password1');
    s.d['steps'] = 5000;
    s.save();
    s.signOut();

    expect(s.hasActiveSession, isFalse);
    expect(s.d['user'], isNull);
    expect(s.sp.getString(emailStorageKey('a@b.com')), isNotNull);

    final next = await freshStore();
    expect(await next.login(email: 'a@b.com', password: 'password1'),
        AuthResult.success);
    expect(next.steps, 5000);
    expect(next.d['name'], 'A');
  });

  test('email accounts keep separate fitness data', () async {
    final s = await freshStore();
    await s.register(name: 'First', email: 'first@b.com', password: 'password1');
    await s.login(email: 'first@b.com', password: 'password1');
    s.d['steps'] = 1200;
    s.save();

    await s.register(
      name: 'Second',
      email: 'second@b.com',
      password: 'password2',
    );
    expect(s.steps, 0);

    s.signOut();
    await s.login(email: 'first@b.com', password: 'password1');
    expect(s.steps, 1200);
    expect(s.d['name'], 'First');
  });

  test('changePassword requires the current password and re-hashes', () async {
    final s = await freshStore();
    await s.register(name: 'A', email: 'a@b.com', password: 'password1');
    await s.login(email: 'a@b.com', password: 'password1');

    // Wrong current password must fail and leave the credential intact.
    expect(
      await s.changePassword(
        currentPassword: 'not-my-password',
        newPassword: 'newpassword',
      ),
      PasswordChangeResult.wrongCurrentPassword,
    );
    s.signOut();
    expect(
      await s.login(email: 'a@b.com', password: 'password1'),
      AuthResult.success,
    );

    // Short new passwords are rejected without verifying anything.
    expect(
      await s.changePassword(
        currentPassword: 'password1',
        newPassword: 'short',
      ),
      PasswordChangeResult.invalidInput,
    );

    // A correct current password allows the change.
    expect(
      await s.changePassword(
        currentPassword: 'password1',
        newPassword: 'newpassword',
      ),
      PasswordChangeResult.success,
    );
    s.signOut();
    expect(
      await s.login(email: 'a@b.com', password: 'password1'),
      AuthResult.wrongPassword,
    );
    expect(
      await s.login(email: 'a@b.com', password: 'newpassword'),
      AuthResult.success,
    );

    // Google-managed accounts are never subject to local password changes.
    s.signOut();
    s.activateGoogleAccount(
      uid: 'g-1',
      email: 'g@b.com',
      displayName: 'G',
    );
    expect(
      await s.changePassword(
        currentPassword: 'whatever',
        newPassword: 'newpassword',
      ),
      PasswordChangeResult.notEmailAccount,
    );
  });

  test('resetCurrentAccountData keeps identity, profile and goals', () async {
    final s = await freshStore();
    await s.register(name: 'A', email: 'a@b.com', password: 'password1');
    await s.login(email: 'a@b.com', password: 'password1');
    s.d['steps'] = 900;
    s.d['name'] = 'Keep Me';
    s.d['age'] = 34;
    s.d['h'] = 176;
    s.d['goal'] = {'w': 72.0, 'd': 'cut', 'wk': 4, 'sw': 80.0};
    s.d['nutritionGoals'] = {
      'calories': 1800,
      'protein': 150,
      'carbs': 180,
      'fat': 55,
    };
    s.save();

    s.resetCurrentAccountData();

    // Fitness records are gone.
    expect(s.steps, 0);
    expect(s.meals, isEmpty);
    expect(s.hist, isEmpty);
    expect(s.routines, isEmpty);
    expect(s.d['log'], isEmpty);
    expect(s.d.containsKey('activeW'), isFalse);

    // Identity, profile details and goals survive the reset.
    expect(s.d['user'], 'a@b.com');
    expect(s.d['name'], 'Keep Me');
    expect(s.d['age'], 34);
    expect(s.d['h'], 176);
    expect(s.goal['w'], 72.0);
    expect(s.goal['sw'], 80.0);
    expect(s.nutritionGoals['calories'], 1800);
    expect(s.d['cred'], isA<Map>());
    expect(s.hasActiveSession, isTrue);

    s.signOut();
    expect(
      await s.login(email: 'a@b.com', password: 'password1'),
      AuthResult.success,
    );
    expect(s.d['name'], 'Keep Me');
    expect(s.goal['w'], 72.0);
    expect(s.steps, 0);
  });

  test('legacy plaintext email account migrates to a hashed snapshot', () async {
    final legacy = <String, dynamic>{
      'user': 'old@b.com',
      'lastUser': 'old@b.com',
      'pw': 'legacy-pass',
      'name': 'Old User',
      'steps': 42,
      'routines': <Map<String, dynamic>>[],
      'sch': <Map<String, dynamic>>[],
      'water': <Map<String, dynamic>>[],
      'act': <Map<String, dynamic>>[],
      'weights': <List<dynamic>>[],
      'meals': <Map<String, dynamic>>[],
      'hist': <Map<String, dynamic>>[],
      'log': <dynamic>[],
      'day': today(),
      'goal': {'w': 0.0, 'd': '', 'wk': 3, 'sw': 0.0},
    };
    SharedPreferences.setMockInitialValues({'ft': jsonEncode(legacy)});

    final s = await freshStore();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ft'), isNull);
    expect(prefs.getString('ft_legacy_backup'), jsonEncode(legacy));
    expect(prefs.getString(emailStorageKey('old@b.com')), isNotNull);
    expect(prefs.getString(emailStorageKey('old@b.com')),
        isNot(contains('legacy-pass')));

    expect(s.hasActiveSession, isFalse);
    expect(
      await s.login(email: 'old@b.com', password: 'legacy-pass'),
      AuthResult.success,
    );
    expect(s.steps, 42);
    expect(s.d['name'], 'Old User');
  });

  test('legacy Google bucket keeps its uid key and drops plaintext pw',
      () async {
    final legacy = <String, dynamic>{
      'user': 'g@b.com',
      'accountId': 'uid-9',
      'authProvider': 'google',
      'name': 'G User',
      'pw': 'should-not-survive',
      'steps': 7,
      'routines': <Map<String, dynamic>>[],
      'sch': <Map<String, dynamic>>[],
      'water': <Map<String, dynamic>>[],
      'act': <Map<String, dynamic>>[],
      'weights': <List<dynamic>>[],
      'meals': <Map<String, dynamic>>[],
      'hist': <Map<String, dynamic>>[],
      'log': <dynamic>[],
      'day': today(),
      'goal': {'w': 0.0, 'd': '', 'wk': 3, 'sw': 0.0},
    };
    SharedPreferences.setMockInitialValues({'ft': jsonEncode(legacy)});

    final s = await freshStore();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ft'), isNull);
    final bucket = prefs.getString('ft_account_uid-9');
    expect(bucket, isNotNull);
    expect(bucket, isNot(contains('should-not-survive')));

    s.activateGoogleAccount(
      uid: 'uid-9',
      email: 'g@b.com',
      displayName: 'G User',
    );
    expect(s.steps, 7);
    expect(s.hasActiveSession, isTrue);
    expect(s.isEmailAccount, isFalse);
    expect(s.d['accountId'], 'uid-9');
    expect(s.d['authProvider'], 'google');
  });

  test('legacy data without a verifiable owner is not claimed', () async {
    SharedPreferences.setMockInitialValues({
      'ft': jsonEncode({'user': 'anon@b.com', 'steps': 99}),
    });

    final s = await freshStore();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ft'), isNull);
    expect(prefs.getString('ft_legacy_backup'), isNotNull);
    expect(s.hasActiveSession, isFalse);
    expect(s.d['user'], isNull);
    expect(s.steps, 0);
  });

  test('undecodable legacy bucket is backed up and startup stays safe',
      () async {
    SharedPreferences.setMockInitialValues({'ft': '{not json'});

    final s = await freshStore();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ft'), isNull);
    expect(prefs.getString('ft_legacy_backup'), '{not json');
    expect(s.hasActiveSession, isFalse);
    expect(s.d['user'], isNull);
  });

  test('corrupt account snapshot signs out instead of crashing', () async {
    final s = await freshStore();
    await s.register(name: 'A', email: 'a@b.com', password: 'password1');
    await s.login(email: 'a@b.com', password: 'password1');
    final key = emailStorageKey('a@b.com');
    s.sp.setString(key, '%%broken%%');

    final next = await freshStore();
    expect(next.hasActiveSession, isFalse);
    expect(next.d['user'], isNull);
    // The corrupt bucket is left on disk for manual recovery.
    expect(next.sp.getString(key), '%%broken%%');
  });

  test('web (chunked) hashing matches the isolate task byte-for-byte', () async {
    // Existing credentials were hashed by the sync/compute path; the web
    // driver must derive the exact same bytes or old logins would break.
    final cases = <(int, int)>[
      (1, 32),
      (2, 32),
      (1000, 32),
      (1000, 48), // spans two SHA-256 blocks
    ];
    for (final (iterations, keyLength) in cases) {
      final args = <String, dynamic>{
        'password': 'correct horse',
        'salt': List<int>.generate(16, (i) => (i * 7) % 251),
        'iterations': iterations,
        'keyLength': keyLength,
      };
      expect(
        await pbkdf2ChunkedForTest(args),
        pbkdf2SyncForTest(args),
        reason: 'iterations=$iterations keyLength=$keyLength',
      );
    }
  });

  test('corrupt stored salt throws out of login instead of being swallowed',
      () async {
    final s = await freshStore();
    s.sp.setString(
      emailStorageKey('bad@b.com'),
      jsonEncode({
        'user': 'bad@b.com',
        'cred': <String, dynamic>{
          'alg': 'pbkdf2-hmac-sha256',
          'salt': '@@@not-base64@@@',
          'hash': 'AA==',
          'iters': 1000,
        },
      }),
    );

    // The auth screen relies on this throwing so it can reset the busy
    // button and show a message; login must not swallow it silently.
    await expectLater(
      s.login(email: 'bad@b.com', password: 'password1'),
      throwsA(isA<FormatException>()),
    );
    expect(s.hasActiveSession, isFalse);
  });

  test('local email sessions have no cloud uid; Google sessions persist theirs',
      () async {
    final s = await freshStore();
    await s.register(name: 'A', email: 'a@b.com', password: 'password1');
    await s.login(email: 'a@b.com', password: 'password1');
    expect(s.sessionUid, isNull);
    expect(s.isCloudLinked, isFalse);
    s.signOut();

    s.activateGoogleAccount(uid: 'uid-42', email: 'g@b.com', displayName: 'G');
    expect(s.sessionUid, 'uid-42');
    expect(s.isCloudLinked, isTrue);

    // The uid survives an app restart via the session pointer.
    final next = await freshStore();
    expect(next.hasActiveSession, isTrue);
    expect(next.sessionUid, 'uid-42');
    next.signOut();
    expect(next.sessionUid, isNull);
  });

  test('signOutAsync clears the session exactly like signOut', () async {
    final s = await freshStore();
    await s.register(name: 'A', email: 'a@b.com', password: 'password1');
    await s.login(email: 'a@b.com', password: 'password1');
    s.d['steps'] = 3000;
    s.save();

    await s.signOutAsync();

    expect(s.hasActiveSession, isFalse);
    expect(s.sessionUid, isNull);
    expect(s.sp.getString(emailStorageKey('a@b.com')), isNotNull);
    expect(
      await s.login(email: 'a@b.com', password: 'password1'),
      AuthResult.success,
    );
    expect(s.steps, 3000);
  });

  test('sendPasswordReset rejects bad input and reports offline service',
      () async {
    final s = await freshStore();

    expect(await s.sendPasswordReset(''), AuthResult.invalidInput);
    expect(await s.sendPasswordReset('not-an-email'), AuthResult.invalidInput);
    // No Firebase app in tests: the cloud path is unavailable and must be
    // reported as a service error, never as success or unknownEmail.
    expect(
      await s.sendPasswordReset('someone@b.com'),
      AuthResult.serviceError,
    );
  });

  test('login keeps working fully offline when no Firebase app exists',
      () async {
    final s = await freshStore();
    await s.register(name: 'A', email: 'a@b.com', password: 'password1');
    s.signOut();

    // Confirm callbacks are supplied but must never be invoked without a
    // Firebase app: there is nothing to confirm against.
    var cloudPrompted = 0;
    var offlinePrompted = 0;
    final result = await s.login(
      email: 'a@b.com',
      password: 'password1',
      requestCloudAccountCreation: (_) async {
        cloudPrompted++;
        return true;
      },
      requestOfflineFallback: (_) async {
        offlinePrompted++;
        return true;
      },
    );

    expect(result, AuthResult.success);
    expect(cloudPrompted, 0);
    expect(offlinePrompted, 0);
    expect(s.sessionUid, isNull);
  });

  test('cloud payload never contains password material', () async {
    final s = await freshStore();
    await s.register(name: 'A', email: 'a@b.com', password: 'password1');
    await s.login(email: 'a@b.com', password: 'password1');

    final payload = sanitizedAccountForCloud(Map<String, dynamic>.from(s.d));

    expect(payload.containsKey('cred'), isFalse);
    expect(payload.containsKey('cloudOptOut'), isFalse);
    expect(payload['user'], 'a@b.com');
    expect(payload['name'], 'A');
    // No secret material leaks through nested keys either.
    expect(jsonEncode(payload), isNot(contains('pbkdf2')));
    expect(jsonEncode(payload), isNot(contains('salt')));
  });

  test('canonicalAccountHash is stable across key order and content-sensitive',
      () async {
    final a = <String, dynamic>{
      'user': 'a@b.com',
      'steps': 10,
      'goal': {'w': 1.0, 'd': '', 'wk': 3},
    };
    final b = <String, dynamic>{
      'goal': {'wk': 3, 'd': '', 'w': 1.0},
      'steps': 10,
      'user': 'a@b.com',
    };
    expect(canonicalAccountHash(a), canonicalAccountHash(b));

    final c = Map<String, dynamic>.from(a)..['steps'] = 11;
    expect(canonicalAccountHash(a), isNot(canonicalAccountHash(c)));
  });
}
