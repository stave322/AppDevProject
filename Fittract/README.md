# FitTrack

## Configuration status (as of this source audit)

The following expected files are **not present in the repository**:

- `android/app/google-services.json` — absent
- `ios/Runner/GoogleService-Info.plist` — absent
- `lib/firebase_options.dart` — absent

Therefore **Firebase is not configured**. No keys, client IDs, or
credentials are stored in this repository, and none should be invented.
The application ID remains `com.example.fittract`. Google sign-in cannot be
verified until real configuration files are supplied.

## Configure Google sign-in (Android)

FitTrack uses Firebase Authentication with Google as its sign-in provider.
Before signing in with Google:

1. In the Firebase Console, create or select your Firebase project and add an
   Android app with the package name `com.example.fittract`.
2. Download that app's `google-services.json` and place it at
   `android/app/google-services.json`.
3. In **Authentication → Sign-in method**, enable the **Google** provider.
4. Add the SHA-1 signing certificate for each build variant you use to the
   Android app settings in Firebase. You can find the local debug certificate
   with `cd android` followed by `.\gradlew signingReport`.
5. Rebuild the Android app after adding the configuration.

The Google Services Gradle plugin (`android/app/build.gradle.kts`) applies
only when `google-services.json` exists. Until Firebase is configured, the
rest of the app remains usable and the Google sign-in button displays a
setup message (`googleAuthErrorMessage` maps `core/no-options` and related
codes to a setup hint).

iOS additionally requires:

- `ios/Runner/GoogleService-Info.plist` added to the Xcode project, and
- a `CFBundleURLTypes` entry with the Google reversed client ID.

Google accounts authenticate through Firebase. Fitness records are currently
stored locally on the device, scoped separately for each Google account; they
are not synchronized between devices.

## Production release blockers

`android/app/build.gradle.kts` still signs release builds with the debug
key and carries the upstream TODO to add a real signing config. Before a
production release, a real keystore must be created and configured — do not
commit keystore passwords or use fabricated credentials. The application ID
is intentionally left as `com.example.fittract` for now.

## Notification status: not implemented

There is no notification plugin dependency in `pubspec.yaml` or
`pubspec.lock` (no `flutter_local_notifications` or equivalent), and no
scheduling code. Adding a dependency requires `flutter pub get`, which was
outside the scope of this source-only change, so **system notifications and
recurring notification schedules are not available**.

What exists instead is honest in-app reminder UI:

- The `wr`/`wtr`/`mr` toggles in Profile control reminder *cards* rendered
  on the Today screen (`store.notes()`), labeled "(in-app)".
- The Schedule tab shows an in-app reminder toggle with copy stating that
  system notifications are not available yet.

To implement real reminders later: pick a notification plugin, add it to
`pubspec.yaml`, run dependency resolution, request POST_NOTIFICATIONS on
Android 13+, store a notification ID per schedule entry, and
schedule/cancel/update notifications alongside every `store.sch` mutation,
including recurrence rules and past-time handling.

## Data retention policy

`Store.applyRetention()` (in `lib/store/store.dart`) runs after every daily
rollover and is the only place that trims the unbounded collections:

- `water`: newest 90 days of dated entries (`kWaterRetentionDays`).
- `log`: newest 365 archived-day entries (`kLogRetentionDays`).
- `hist`: workouts from the last 365 days (`kHistRetentionDays`).

Entries with missing or unparseable dates are always kept; data is only
removed when it is provably older than its bound. Daily rollover itself
preserves history by archiving meals/activity/steps into `log` before the
counters reset, and never modifies `hist`.
