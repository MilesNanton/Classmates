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
import 'sign_up_screen.dart';
import 'splash_screen.dart';
import 'welcome_onboarding.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
Future<void>? _googleSignInInitialization;

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onTakeTour,
    this.onGetStarted,
    this.onCancel,
    this.onTermsOfService,
    this.onPrivacyPolicy,
  });

  final VoidCallback? onTakeTour;
  final VoidCallback? onGetStarted;
  final VoidCallback? onCancel;
  final VoidCallback? onTermsOfService;
  final VoidCallback? onPrivacyPolicy;

  Future<void> _showSignInOptions(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SignInOptionsSheet(
        onGoogle: () => _signInWithGoogle(context),
        onApple: () => _signInWithApple(context),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      if (kDebugMode) debugPrint('[GoogleSignIn] Initializing');
      _googleSignInInitialization ??= _googleSignIn.initialize();
      await _googleSignInInitialization;

      if (kDebugMode) debugPrint('[GoogleSignIn] Opening account picker');
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw StateError('Google Sign-In returned no ID token.');
      }

      if (kDebugMode) debugPrint('[GoogleSignIn] Signing in to Firebase');
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
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

      if (!context.mounted) return;
      await _openPostLoginScreen(context, user);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        if (kDebugMode) debugPrint('[GoogleSignIn] Cancelled by user');
        return;
      }
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] Google error: ${error.code}');
        debugPrint('[GoogleSignIn] ${error.description}');
      }
      if (!context.mounted) return;
      showMessagePopup(
        context,
        message:
            error.code == GoogleSignInExceptionCode.clientConfigurationError
            ? 'Google Sign-In is not configured correctly.'
            : 'Unable to sign in with Google. Please try again.',
        type: MessageType.error,
      );
    } on FirebaseAuthException catch (error) {
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] Firebase Auth error: ${error.code}');
      }
      if (!context.mounted) return;
      showMessagePopup(
        context,
        message: error.message ?? 'Unable to sign in with Google.',
        type: MessageType.error,
      );
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] Firestore error: ${error.code}');
      }
      if (!context.mounted) return;
      showMessagePopup(
        context,
        message:
            'Google account connected, but the profile could not be saved.',
        type: MessageType.error,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] Unexpected error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!context.mounted) return;
      showMessagePopup(
        context,
        message: 'Unable to sign in with Google. Please try again.',
        type: MessageType.error,
      );
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
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
      if (!context.mounted) return;

      await _openPostLoginScreen(context, user);
    } on FirebaseAuthException catch (error) {
      if (!context.mounted || error.code == 'web-context-cancelled') return;

      showMessagePopup(
        context,
        message: error.message ?? 'Unable to sign in. Please try again.',
        type: MessageType.error,
      );
    } on FirebaseException {
      if (!context.mounted) return;
      showMessagePopup(
        context,
        message: 'Apple account connected, but the profile could not be saved.',
        type: MessageType.error,
      );
    }
  }

  Future<void> _openPostLoginScreen(BuildContext context, User user) async {
    final onboardingCompleted = await hasCompletedOnboarding(user);
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => onboardingCompleted
            ? const CommunityHomeScreen(showGuidelines: true)
            : const WelcomeOnboarding(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: ClassmatesColors.green,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: ClassmatesColors.green,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: ClassmatesColors.green,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(21, 56, 21, 25),
            child: Column(
              children: [
                Text(
                  'CLASSMATES',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  flex: 5,
                  child: Center(
                    child: Image.asset(
                      'assets/homeimage.png',
                      width: 300,
                      height: 330,
                      fit: BoxFit.contain,
                      semanticLabel: 'Classmates hugging',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Homeschooling Adventures',
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onTakeTour ?? () {},
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Take a tour',
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: 0,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 378,
                  height: 48,
                  child: FilledButton(
                    onPressed:
                        onGetStarted ?? () => _showSignInOptions(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF05662F),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF05662F),
                      disabledForegroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Let’s get started',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                Text(
                  'By signing up, you agree with the Class Mates',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FooterLink(
                      label: 'Terms of Service',
                      onPressed: onTermsOfService,
                    ),
                    Text(
                      ' and ',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                    _FooterLink(
                      label: 'Privacy Policies.',
                      onPressed: onPrivacyPolicy,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInOptionsSheet extends StatelessWidget {
  const _SignInOptionsSheet({required this.onGoogle, required this.onApple});

  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F1F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Color(0xFF777777),
                    ),
                  ),
                ),
              ),
              _SignInOption(
                icon: const Icon(
                  Icons.mail,
                  color: Color(0xFF13AD59),
                  size: 20,
                ),
                label: 'Continue with Email',
                onTap: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SignUpScreen(),
                    ),
                  );
                },
              ),
              _SignInOption(
                icon: Image.asset(
                  'assets/googleIcon.svg.webp',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
                label: 'Continue with Google',
                onTap: () {
                  Navigator.of(context).pop();
                  onGoogle();
                },
              ),
              _SignInOption(
                icon: const Icon(Icons.apple, color: Colors.black, size: 22),
                label: 'Continue with Apple',
                onTap: () {
                  Navigator.of(context).pop();
                  onApple();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInOption extends StatelessWidget {
  const _SignInOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: SizedBox(
          height: 46,
          width: double.infinity,
          child: Row(
            children: [
              SizedBox(width: 24, child: Center(child: icon)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    color: const Color(0xFF3F3F46),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 11,
            height: 1.3,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
