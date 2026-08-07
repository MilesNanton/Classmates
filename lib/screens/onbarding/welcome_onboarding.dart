import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'onboarding_stage_1.dart';

class WelcomeOnboarding extends StatelessWidget {
  const WelcomeOnboarding({super.key, this.onContinue});

  final VoidCallback? onContinue;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 32),
                child: Column(
                  children: [
                    SizedBox(
                      height: constraints.maxHeight * 0.53,
                      child: Center(
                        child: Image.asset(
                          'assets/homeimage.png',
                          width: 300,
                          fit: BoxFit.contain,
                          semanticLabel: 'Classmates hugging',
                        ),
                      ),
                    ),
                    Text(
                      'Welcome to Classmates',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        color: const Color(0xFF525252),
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Let's set up your classroom in just a few\n"
                      "steps. We'll tailor the experience to suit\n"
                      "your family's homeschooling journey.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        color: const Color(0xFF525252),
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 51,
                      child: FilledButton(
                        onPressed: () {
                          if (onContinue case final callback?) {
                            callback();
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const OnboardingStage1(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00A94F),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF00A94F),
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
