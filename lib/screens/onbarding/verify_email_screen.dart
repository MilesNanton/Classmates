import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/message_widget.dart';
import 'welcome_onboarding.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.email});

  final String? email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;

  void _log(String message) {
    if (kDebugMode) debugPrint('[VerifyEmail] $message');
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    _log('Checking email verification status');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('No signed-in user found.');
      }

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser?.emailVerified ?? false) {
        _log('Email is verified; opening welcome screen');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const WelcomeOnboarding()),
        );
        return;
      }

      _log('Email is not verified yet');
      if (!mounted) return;
      showMessagePopup(
        context,
        message: 'Email is not verified yet. Please check your inbox.',
        type: MessageType.error,
      );
    } on FirebaseAuthException catch (error) {
      _log('Verification check failed: ${error.code}');
      if (!mounted) return;
      showMessagePopup(
        context,
        message: error.message ?? 'Unable to check verification status.',
        type: MessageType.error,
      );
    } catch (error, stackTrace) {
      _log('Unexpected verification check error: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      showMessagePopup(
        context,
        message: 'Unable to check verification status. Please try again.',
        type: MessageType.error,
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendEmail() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    _log('Resending verification email');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('No signed-in user found.');
      }
      await user.sendEmailVerification();
      _log('Verification email resent');
      if (!mounted) return;
      showMessagePopup(context, message: 'Verification email sent again.');
    } on FirebaseAuthException catch (error) {
      _log('Resend failed: ${error.code}');
      if (!mounted) return;
      showMessagePopup(
        context,
        message: error.code == 'too-many-requests'
            ? 'Please wait before requesting another email.'
            : error.message ?? 'Unable to resend the verification email.',
        type: MessageType.error,
      );
    } catch (error, stackTrace) {
      _log('Unexpected resend error: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      showMessagePopup(
        context,
        message: 'Unable to resend the verification email.',
        type: MessageType.error,
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
            child: Column(
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
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Sign up',
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF71717A),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 76),
                Text(
                  'Verify email',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF52525B),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email == null
                      ? "We've sent a verification email. Please\nverify and come back."
                      : "We've sent a verification email to\n${widget.email}. Please verify and come back.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF52525B),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 74),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isChecking ? null : _checkVerification,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF13AD59),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF13AD59),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      'Check Verification',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 44),
                TextButton(
                  onPressed: _isResending ? null : _resendEmail,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF71717A),
                  ),
                  child: _isResending
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(
                    'Resend email',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
