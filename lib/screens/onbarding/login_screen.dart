import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/auth_destination_service.dart';
import '../../widgets/message_widget.dart';
import '../../services/user_profile_service.dart';
import '../Home/Home_screen.dart';
import 'welcome_onboarding.dart';

final GoogleSignIn _loginGoogleSignIn = GoogleSignIn.instance;
Future<void>? _loginGoogleSignInInitialization;

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onContinue,
    this.onForgotPassword,
    this.onGoogle,
    this.onApple,
  });

  final VoidCallback? onContinue;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  void _log(String message) {
    if (kDebugMode) debugPrint('[Login] $message');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      _log('Email/password validation failed');
      return;
    }

    setState(() => _isLoading = true);
    _log('Email/password sign-in started');

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      _log('Email/password sign-in succeeded');

      if (!mounted) {
        _log('Screen was disposed before navigation');
        return;
      }

      await _openPostLoginScreen(onSignedIn: widget.onContinue);
    } on FirebaseAuthException catch (error) {
      _log('Email/password sign-in failed: ${error.code}');
      if (mounted) _showMessage(_authErrorMessage(error), isError: true);
    } catch (error, stackTrace) {
      _log('Unexpected email/password sign-in error: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showMessage('Something went wrong. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      _log('Password reset validation failed');
      _showMessage('Enter a valid email address first.', isError: true);
      return;
    }

    _log('Password reset request started');
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _log('Password reset request succeeded');
      if (mounted) {
        _showMessage('Password reset email sent.');
        widget.onForgotPassword?.call();
      }
    } on FirebaseAuthException catch (error) {
      _log('Password reset request failed: ${error.code}');
      if (mounted) _showMessage(_authErrorMessage(error), isError: true);
    }
  }

  Future<void> _signInWithApple() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    _log('Apple sign-in started');

    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      final credential = await FirebaseAuth.instance.signInWithProvider(
        provider,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase did not return the signed-in user.');
      }
      await saveSocialUserProfile(user: user, authProvider: 'apple');
      _log('Apple sign-in succeeded');

      if (!mounted) {
        _log('Screen was disposed before navigation');
        return;
      }

      await _openPostLoginScreen(onSignedIn: widget.onApple);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'web-context-cancelled') {
        _log('Apple sign-in cancelled');
        return;
      }
      _log('Apple sign-in failed: ${error.code}');
      if (!mounted) return;
      _showMessage(_authErrorMessage(error), isError: true);
    } catch (error, stackTrace) {
      _log('Unexpected Apple sign-in error: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showMessage(
          'Unable to sign in with Apple. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    _log('Google sign-in started');

    try {
      _loginGoogleSignInInitialization ??= _loginGoogleSignIn.initialize();
      await _loginGoogleSignInInitialization;

      _log('Opening Google account picker');
      final googleUser = await _loginGoogleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google Sign-In returned no ID token.');
      }

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      final user = userCredential.user;
      if (user == null) {
        throw StateError('Firebase did not return the signed-in user.');
      }

      await saveSocialUserProfile(
        user: user,
        authProvider: 'google',
        preferredName: googleUser.displayName,
      );

      _log('Google sign-in succeeded');
      if (!mounted) return;
      await _openPostLoginScreen(onSignedIn: widget.onGoogle);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        _log('Google sign-in cancelled');
        return;
      }
      _log('Google sign-in failed: ${error.code}');
      if (!mounted) return;
      _showMessage(
        error.code == GoogleSignInExceptionCode.clientConfigurationError
            ? 'Google Sign-In is not configured correctly.'
            : 'Unable to sign in with Google. Please try again.',
        isError: true,
      );
    } on FirebaseAuthException catch (error) {
      _log('Firebase Google sign-in failed: ${error.code}');
      if (mounted) _showMessage(_authErrorMessage(error), isError: true);
    } on FirebaseException catch (error) {
      _log('Saving Google profile failed: ${error.code}');
      if (mounted) {
        _showMessage(
          'Google account connected, but the profile could not be saved.',
          isError: true,
        );
      }
    } catch (error, stackTrace) {
      _log('Unexpected Google sign-in error: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showMessage(
          'Unable to sign in with Google. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _openPostLoginScreen({VoidCallback? onSignedIn}) async {
    if (onSignedIn != null) {
      _log('Successful sign-in handed off to callback');
      onSignedIn();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final onboardingCompleted =
        user != null && await hasCompletedOnboarding(user);
    if (!mounted) return;

    _log(
      onboardingCompleted
          ? 'Returning user; opening community home'
          : 'New user; opening onboarding',
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => onboardingCompleted
            ? const CommunityHomeScreen(showGuidelines: true)
            : const WelcomeOnboarding(),
      ),
      (_) => false,
    );
  }

  String _authErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'Incorrect email or password.',
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' => 'Check your internet connection.',
      'operation-not-allowed' =>
        'This sign-in method is not enabled in Firebase Authentication.',
      'web-context-cancelled' => 'Apple sign-in was cancelled.',
      _ => error.message ?? 'Unable to log in. Please try again.',
    };
  }

  void _showMessage(String message, {bool isError = false}) {
    showMessagePopup(
      context,
      message: message,
      type: isError ? MessageType.error : MessageType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                children: [
                  SizedBox(
                    height: 34,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF3F3F46),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(58, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.chevron_left, size: 24),
                            label: Text(
                              'Back',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Log in',
                          style: GoogleFonts.lato(
                            color: const Color(0xFF71717A),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  _LoginTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Email is required';
                      if (!_isValidEmail(email)) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _LoginTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _signIn(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 22,
                        color: const Color(0xFF7A7A7A),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _sendPasswordReset,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF52525B),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot password?',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF13AD59),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Continue',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFE4E4E7))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        child: Text(
                          'OR',
                          style: GoogleFonts.lato(
                            color: const Color(0xFF52525B),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFE4E4E7))),
                    ],
                  ),
                  const SizedBox(height: 13),
                  _SocialLoginButton(
                    icon: Image.asset(
                      'assets/googleIcon.svg.webp',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                    label: 'Continue with Google',
                    onPressed: _isLoading ? null : _signInWithGoogle,
                  ),
                  const SizedBox(height: 8),
                  _SocialLoginButton(
                    icon: const Icon(
                      Icons.apple,
                      size: 22,
                      color: Colors.black,
                    ),
                    label: 'Continue with Apple',
                    onPressed: _isLoading ? null : _signInWithApple,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.label,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      obscuringCharacter: '•',
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.lato(color: const Color(0xFF18181B), fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lato(
          color: const Color(0xFF18181B),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.only(bottom: 6),
        isDense: true,
        suffixIcon: suffixIcon,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 30,
          minHeight: 30,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE4E4E7)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF13AD59), width: 1.5),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3F3F46),
          side: const BorderSide(color: Color(0xFFE4E4E7)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, child: Center(child: icon)),
            const SizedBox(width: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
