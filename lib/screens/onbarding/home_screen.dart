import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import 'splash_screen.dart';

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
      builder: (_) => const _SignInOptionsSheet(),
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
            padding: const EdgeInsets.fromLTRB(21, 44, 21, 25),
            child: Column(
              children: [
                Text(
                  'CLASSMATES',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 42),
                Flexible(
                  flex: 5,
                  child: Center(
                    child: Image.asset(
                      'assets/homeimage.png',
                      width: 260,
                      height: 260,
                      fit: BoxFit.contain,
                      semanticLabel: 'Classmates hugging',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Homeschooling Adventures',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: 0,
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
                    style: GoogleFonts.nunito(
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
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                TextButton(
                  onPressed: onCancel ?? () {},
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Cancel anytime',
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By signing up, you agree with the Class Mates',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 10,
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
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 10,
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
  const _SignInOptionsSheet();

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
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
              ),
              _SignInOption(
                icon: Text(
                  'G',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF4285F4),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                label: 'Continue with Google',
                onTap: () {},
              ),
              _SignInOption(
                icon: const Icon(Icons.apple, color: Colors.black, size: 22),
                label: 'Continue with Apple',
                onTap: () {},
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
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: Row(
          children: [
            SizedBox(width: 24, child: Center(child: icon)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                color: const Color(0xFF3F3F46),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
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
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 10,
            height: 1.3,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
