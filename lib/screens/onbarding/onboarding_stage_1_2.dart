import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingStage12 extends StatefulWidget {
  const OnboardingStage12({super.key, this.onContinue});

  final ValueChanged<String>? onContinue;

  @override
  State<OnboardingStage12> createState() => _OnboardingStage12State();
}

class _OnboardingStage12State extends State<OnboardingStage12> {
  static const _approaches = [
    'Traditional',
    'Charlotte Mason',
    'Montessori',
    'Classical Education',
    'Unschooling',
    'Unit Studies',
    'Other',
  ];
  static const _subjects = [
    'English',
    'Mathematics',
    'Science',
    'History',
    'Geography',
    'Music',
    'Art & Design',
  ];

  String? _selectedApproach;
  final Set<String> _selectedSubjects = {};
  bool _isSubjectStep = false;
  bool _isLocationStep = false;
  int? _loadingStep;
  Timer? _loadingTimer;

  static const _loadingMessages = [
    'Building your home feed...',
    'Finding experiences near you...',
    'Just a moment...',
  ];

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingStep case final step?) {
      return _buildLoadingState(step);
    }

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
            padding: const EdgeInsets.fromLTRB(30, 15, 30, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      if (_isLocationStep) {
                        setState(() => _isLocationStep = false);
                      } else if (_isSubjectStep) {
                        setState(() => _isSubjectStep = false);
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4B4B4B),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(70, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.chevron_left, size: 27),
                    label: Text(
                      'Back',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 19),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _isLocationStep
                        ? 0.97
                        : _isSubjectStep
                        ? 0.82
                        : 0.6,
                    minHeight: 6,
                    backgroundColor: Color(0xFFECECEC),
                    valueColor: AlwaysStoppedAnimation(Color(0xFF48DA8C)),
                  ),
                ),
                if (_isLocationStep)
                  ..._buildLocationContent()
                else
                  ..._buildSelectionContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSelectionContent() {
    return [
      const SizedBox(height: 35),
      Text(
        _isSubjectStep
            ? 'Which subjects are you focusing\non?'
            : 'How do you like to\nhomeschool?',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: const Color(0xFF525252),
          fontSize: 25,
          fontWeight: FontWeight.w700,
          height: 1.18,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        _isSubjectStep
            ? "Select the subjects you'd like to see the most resources and experiences for."
            : 'Choose your educational approach to discover like-minded families, relevant resources and local experiences.',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: const Color(0xFF525252),
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.35,
        ),
      ),
      const SizedBox(height: 28),
      ...(_isSubjectStep ? _subjects : _approaches).map((option) {
        final isSelected = _isSubjectStep
            ? _selectedSubjects.contains(option)
            : option == _selectedApproach;
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: SizedBox(
            width: double.infinity,
            height: 47,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  if (_isSubjectStep) {
                    if (!_selectedSubjects.add(option)) {
                      _selectedSubjects.remove(option);
                    }
                  } else {
                    _selectedApproach = option;
                  }
                });
              },
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                backgroundColor: isSelected
                    ? const Color(0xFF3159AA)
                    : Colors.white,
                foregroundColor: isSelected
                    ? Colors.white
                    : const Color(0xFF737373),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF3159AA)
                      : const Color(0xFFD4D4D4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                option,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }),
      const Spacer(),
      _bottomButton(
        label: 'Continue',
        enabled: _isSubjectStep
            ? _selectedSubjects.isNotEmpty
            : _selectedApproach != null,
        onPressed: () {
          if (!_isSubjectStep) {
            setState(() => _isSubjectStep = true);
          } else {
            setState(() => _isLocationStep = true);
          }
        },
      ),
    ];
  }

  List<Widget> _buildLocationContent() {
    return [
      const SizedBox(height: 35),
      Text(
        'Share your location',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: const Color(0xFF525252),
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        "We'll use your location to recommend nearby learning experiences and connect you with your local homeschooling community.",
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: const Color(0xFF525252),
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.35,
        ),
      ),
      const Spacer(flex: 2),
      Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFFDCE8FF),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF4285F4),
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: Colors.white, width: 4),
            ),
          ),
        ),
      ),
      const Spacer(flex: 3),
      TextButton(
        onPressed: () => widget.onContinue?.call(_selectedApproach!),
        child: Text(
          "I'll do this later",
          style: GoogleFonts.nunito(
            color: const Color(0xFF737373),
            fontSize: 15,
          ),
        ),
      ),
      const SizedBox(height: 18),
      _bottomButton(
        label: 'Share my location',
        enabled: true,
        onPressed: _startLoadingSequence,
      ),
    ];
  }

  Widget _bottomButton({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF00A94F),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB7B7B7),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _startLoadingSequence() {
    _loadingTimer?.cancel();
    setState(() => _loadingStep = 0);

    _loadingTimer = Timer.periodic(const Duration(milliseconds: 1600), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final currentStep = _loadingStep ?? 0;
      if (currentStep < _loadingMessages.length - 1) {
        setState(() => _loadingStep = currentStep + 1);
        return;
      }

      timer.cancel();
      widget.onContinue?.call(_selectedApproach!);
    });
  }

  Widget _buildLoadingState(int step) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0DA64A),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0DA64A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0DA64A),
        body: SafeArea(
          child: Center(
            child: Text(
              _loadingMessages[step],
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
