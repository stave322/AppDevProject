import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../store/store.dart';
import '../services/google_auth_service.dart';
import '../widgets/shared_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthState();
}

class _AuthState extends State<AuthScreen> {
  bool reg = false, agree = false;
  bool googleBusy = false, emailBusy = false;
  bool _obscurePw = true, _obscurePw2 = true;
  String err = '';
  String notice = '';
  final googleAuth = GoogleAuthService();
  final nm = TextEditingController(),
      em = TextEditingController(),
      pw = TextEditingController(),
      pw2 = TextEditingController();

  @override
  void dispose() {
    nm.dispose();
    em.dispose();
    pw.dispose();
    pw2.dispose();
    super.dispose();
  }

  String _messageFor(AuthResult result) => switch (result) {
    AuthResult.success => '',
    AuthResult.invalidInput => reg
        ? 'Fill in all fields. Password needs 8+ characters.'
        : 'Enter email and password.',
    AuthResult.unknownEmail => 'No account found for that email.',
    AuthResult.wrongPassword => 'Wrong password.',
    AuthResult.duplicateEmail => 'An account with that email already exists.',
    AuthResult.storageError =>
      'Could not access saved account data. Please try again.',
    AuthResult.serviceError =>
      'Could not reach the account service. Check your connection and try again.',
  };

  Future<bool> _confirmCloudAccount(String message) async {
    if (!mounted) return false;
    return confirm(context, message, 'Create cloud account');
  }

  Future<bool> _confirmOfflineFallback(String message) async {
    if (!mounted) return false;
    return confirm(context, message, 'Continue offline');
  }

  Future<void> submit() async {
    if (emailBusy) return;
    if (!reg) {
      if (em.text.trim().isEmpty || pw.text.isEmpty) {
        return setState(() => err = 'Enter email and password.');
      }
    } else {
      if (nm.text.trim().isEmpty || em.text.trim().isEmpty) {
        return setState(() => err = 'Fill in all fields.');
      }
      if (pw.text.length < 8) {
        return setState(() => err = 'Password needs 8+ characters.');
      }
      if (pw.text != pw2.text) {
        return setState(() => err = 'Passwords do not match.');
      }
      if (!agree) return setState(() => err = 'Please accept the terms.');
    }

    setState(() {
      emailBusy = true;
      err = '';
      notice = '';
    });
    // Paint the busy indicator before hashing starts. On the web, compute()
    // runs PBKDF2 synchronously on the UI thread for its whole duration, so
    // without this yield the last pressed-button frame (with its ink ripple)
    // freezes on screen and the spinner never gets to appear.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    AuthResult result;
    try {
      result = reg
          ? await store.register(
              name: nm.text.trim(),
              email: em.text.trim(),
              password: pw.text,
            )
          : await store.login(
              email: em.text.trim(),
              password: pw.text,
              requestCloudAccountCreation: _confirmCloudAccount,
              requestOfflineFallback: _confirmOfflineFallback,
            );
    } catch (_) {
      // Storage or hashing threw: never leave the button stuck in its busy
      // state — reset it and surface a useful message instead.
      if (!mounted) return;
      setState(() {
        emailBusy = false;
        err = 'Something went wrong. Please try again.';
      });
      return;
    }
    if (!mounted) return;
    if (reg && result == AuthResult.success) {
      // Account creation succeeds but deliberately leaves the app signed
      // out: return to the Login form with a success note. The dashboard
      // stays reachable only through a separate, successful login.
      setState(() {
        emailBusy = false;
        reg = false;
        agree = false;
        pw.clear();
        pw2.clear();
        notice = 'Account created successfully. Please log in.';
      });
      return;
    }
    setState(() {
      emailBusy = false;
      err = _messageFor(result);
    });
  }

  Future<void> forgotPassword() async {
    final email = em.text.trim();
    if (email.isEmpty) {
      snack(context, 'Enter your email address first.');
      return;
    }
    final result = await store.sendPasswordReset(email);
    if (!mounted) return;
    final message = switch (result) {
      AuthResult.success =>
        'If an account exists for this email, a password reset link is on its way.',
      AuthResult.unknownEmail =>
        'No cloud account was found for that email. On-device accounts cannot be reset remotely.',
      AuthResult.invalidInput => 'Enter a valid email address.',
      _ =>
        'Could not reach the account service. Check your connection and try again.',
    };
    snack(context, message);
  }

  Future<void> signInWithGoogle() async {
    if (reg && !agree) {
      setState(() => err = 'Please accept the terms.');
      return;
    }
    setState(() {
      googleBusy = true;
      err = '';
      notice = '';
    });
    try {
      final credential = await googleAuth.signIn();
      final user = credential.user;
      if (user == null) {
        throw StateError('Google sign-in did not return an account.');
      }
      store.activateGoogleAccount(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? nm.text,
      );
    } on GoogleSignInException catch (error) {
      _showGoogleError(googleAuthErrorMessage(error));
    } on FirebaseAuthException catch (error) {
      _showGoogleError(googleAuthErrorMessage(error));
    } on FirebaseException catch (error) {
      _showGoogleError(googleAuthErrorMessage(error));
    } on StateError catch (error) {
      _showGoogleError(googleAuthErrorMessage(error));
    } catch (error) {
      // Anything unexpected (plugin-channel failures, unsupported
      // platforms, …) gets the generic mapped fallback: a short, safe
      // message with no raw error details, tokens or configuration text.
      _showGoogleError(googleAuthErrorMessage(error));
    } finally {
      if (mounted) setState(() => googleBusy = false);
    }
  }

  void _showGoogleError(String message) {
    if (message.isNotEmpty && mounted) setState(() => err = message);
  }

  Widget _visibilityToggle({
    required bool obscured,
    required VoidCallback onToggle,
  }) => IconButton(
    icon: Icon(
      obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    ),
    tooltip: obscured ? 'Show password' : 'Hide password',
    onPressed: onToggle,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(kGapXl),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C5A5A), kDk],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '▲ FITTRACK',
                  style: TextStyle(color: kMint, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 40),
                Text(
                  reg
                      ? 'Build a routine.\nFind your rhythm.'
                      : 'Small steps.\nStronger you.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: kGapLg),
          Text(
            reg ? 'Create your account' : 'Welcome back',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: kGapSm),
          if (reg)
            TextField(
              controller: nm,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
          if (reg) const SizedBox(height: kGapMd),
          TextField(
            controller: em,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          const SizedBox(height: kGapMd),
          TextField(
            controller: pw,
            obscureText: _obscurePw,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: _visibilityToggle(
                obscured: _obscurePw,
                onToggle: () => setState(() => _obscurePw = !_obscurePw),
              ),
            ),
          ),
          if (reg) ...[
            const SizedBox(height: kGapMd),
            TextField(
              controller: pw2,
              obscureText: _obscurePw2,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                suffixIcon: _visibilityToggle(
                  obscured: _obscurePw2,
                  onToggle: () => setState(() => _obscurePw2 = !_obscurePw2),
                ),
              ),
            ),
          ],
          if (reg) ...[
            const SizedBox(height: kGapSm),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: agree,
              onChanged: (v) => setState(() => agree = v!),
              title: const Text(
                'I agree to the Terms of Service and Privacy Policy.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
          if (err.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(err, style: const TextStyle(color: kRed)),
            ),
          if (notice.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(notice, style: const TextStyle(color: kPri)),
            ),
          if (!reg)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: forgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
          const SizedBox(height: kGapSm),
          if (emailBusy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(kGapMd),
                child: CircularProgressIndicator(),
              ),
            )
          else
            btn(reg ? 'Create account' : 'Log in', submit),
          if (!reg) ...[
            const SizedBox(height: kGapMd),
            if (googleBusy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(kGapMd),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              btn('Continue with Google', signInWithGoogle, tonal: true),
          ],
          TextButton(
            onPressed: () => setState(() {
              reg = !reg;
              err = '';
              notice = '';
            }),
            child: Text(
              reg ? 'Already a member? Log in' : 'New here? Create an account',
            ),
          ),
        ],
      ),
    ),
  );
}
