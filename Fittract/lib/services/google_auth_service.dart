import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static bool _googleSignInInitialized = false;

  /// Test seam replacing the sign-out routine so widget tests can simulate a
  /// remote failure without a live Firebase/Google SDK. Null in production.
  @visibleForTesting
  static Future<void> Function()? debugSignOutOverride;

  Future<UserCredential> signIn() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleSignInInitialized = true;
    }

    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google did not return an ID token. Check the Firebase Android app and Web client configuration.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    final override = debugSignOutOverride;
    if (override != null) return override();
    if (Firebase.apps.isEmpty) return;
    await FirebaseAuth.instance.signOut();
    if (_googleSignInInitialized) {
      await GoogleSignIn.instance.signOut();
    }
  }
}

String googleAuthErrorMessage(Object error) {
  if (error is FirebaseException) {
    if (error is FirebaseAuthException) return _authErrorMessage(error);
    return switch (error.code) {
      'core/no-app' ||
      'core/no-options' ||
      'core/invalid-app-argument' ||
      'core/initialization-error' => 'Firebase is not configured yet. Add your Firebase Android app configuration and enable Google sign-in.',
      _ => error.message ?? 'Could not connect to Firebase. Please try again.',
    };
  }
  if (error is GoogleSignInException) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled => '',
      GoogleSignInExceptionCode.clientConfigurationError => 'Google sign-in is not configured. Check your Firebase Android app and OAuth client settings.',
      GoogleSignInExceptionCode.providerConfigurationError => 'Google sign-in is unavailable. Check your Firebase Android app and Google provider settings.',
      _ => error.description ?? 'Could not sign in with Google. Check your connection and try again.',
    };
  }
  if (error is StateError) {
    return error.message;
  }
  return 'Google sign-in failed. Please try again.';
}

String _authErrorMessage(FirebaseAuthException error) => switch (error.code) {
  'account-exists-with-different-credential' =>
    'This email is already linked to a different sign-in method.',
  'invalid-credential' =>
    'Google sign-in could not verify your account. Please try again.',
  'operation-not-allowed' =>
    'Google sign-in is not enabled in your Firebase Authentication settings.',
  'network-request-failed' =>
    'Could not connect. Check your internet connection and try again.',
  'missing-google-id-token' =>
    error.message ?? 'Google did not return a sign-in token.',
  _ => error.message ?? 'Google sign-in failed. Please try again.',
};
