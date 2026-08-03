import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/message_widget.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  void _log(String message) {
    if (kDebugMode) debugPrint('[SignUp] $message');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      _log('Form validation failed');
      return;
    }

    setState(() => _isLoading = true);
    _log('Sign-up started');
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      _log('Firebase Auth account created');

      final user = credential.user;
      if (user == null) {
        _log('Firebase Auth returned no user');
        throw StateError('Firebase did not return the created user.');
      }

      final name = _nameController.text.trim();
      await user.updateDisplayName(name);
      _log('Firebase Auth display name updated');

      _log('Saving user profile to Firestore');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': user.email ?? _emailController.text.trim(),
        'authProvider': 'password',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _log('Firestore user profile saved');

      _log('Sending verification email');
      await user.sendEmailVerification();
      _log('Verification email sent');

      if (!mounted) {
        _log('Screen disposed before navigation');
        return;
      }
      _log('Sign-up completed; opening email verification screen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VerifyEmailScreen(email: user.email),
        ),
      );
    } on FirebaseAuthException catch (error) {
      _log('Firebase Auth sign-up failed: ${error.code}');
      if (!mounted) return;
      showMessagePopup(
        context,
        message: _authErrorMessage(error),
        type: MessageType.error,
      );
    } on FirebaseException catch (error) {
      _log('Firestore profile save failed: ${error.code}');
      if (!mounted) return;
      showMessagePopup(
        context,
        message: error.code == 'permission-denied'
            ? 'Your account was created, but the profile could not be saved.'
            : 'Unable to save your profile. Please try again.',
        type: MessageType.error,
      );
    } catch (error, stackTrace) {
      _log('Unexpected sign-up error: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      showMessagePopup(
        context,
        message: 'Something went wrong. Please try again.',
        type: MessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _log('Sign-up loading state cleared');
      }
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => 'An account already exists for this email.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' => 'Use a stronger password with at least 6 characters.',
      'operation-not-allowed' =>
        'Email sign up is not enabled in Firebase Authentication.',
      'network-request-failed' => 'Check your internet connection.',
      _ => error.message ?? 'Unable to create your account. Please try again.',
    };
  }

  void _openLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
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
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _openLogin,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF3F3F46),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(52, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Log in',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SignUpTextField(
                    label: 'Your name',
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Your name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _SignUpTextField(
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
                  const SizedBox(height: 16),
                  _SignUpTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _signUp(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF13AD59),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF13AD59),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Continue',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
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

class _SignUpTextField extends StatelessWidget {
  const _SignUpTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.obscureText = false,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      obscureText: obscureText,
      obscuringCharacter: '•',
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.nunito(color: const Color(0xFF18181B), fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.nunito(
          color: const Color(0xFF18181B),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.only(bottom: 6),
        isDense: true,
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
