import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Home/Home_screen.dart';
import 'home_screen.dart';
import 'verify_email_screen.dart';
import 'welcome_onboarding.dart';

abstract final class ClassmatesColors {
  static const green = Color(0xFF12B76A);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 2), _openNextScreen);
  }

  Future<void> _openNextScreen() async {
    if (!mounted) return;

    Widget destination = const HomeScreen();

    if (Firebase.apps.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        destination = await _signedInDestination(user);
      }
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }

  Future<Widget> _signedInDestination(User user) async {
    try {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) return const HomeScreen();

      final usesPassword = refreshedUser.providerData.any(
        (provider) => provider.providerId == 'password',
      );

      if (usesPassword && !refreshedUser.emailVerified) {
        return VerifyEmailScreen(email: refreshedUser.email);
      }

      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(refreshedUser.uid)
          .get();
      final onboardingCompleted =
          profile.data()?['onboardingCompleted'] == true;
      return onboardingCompleted
          ? const CommunityHomeScreen()
          : const WelcomeOnboarding();
    } on FirebaseException {
      // Firebase Auth already confirmed the persisted session. Keep the
      // signed-in user inside the app if the network/profile is unavailable.
      return const CommunityHomeScreen();
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
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
        body: Center(
          child: Text(
            'CLASSMATES',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
