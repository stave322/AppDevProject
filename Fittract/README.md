# FitTrack

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

The Google Services Gradle plugin is enabled automatically when the
configuration file is present. Until Firebase is configured, the rest of the
app remains usable and the Google sign-in button displays a setup message.

Google accounts authenticate through Firebase. Fitness records are currently
stored locally on the device, scoped separately for each Google account; they
are not synchronized between devices.
