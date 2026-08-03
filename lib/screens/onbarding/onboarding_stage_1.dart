import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'onboarding_stage_1_2.dart';

class OnboardingStage1 extends StatefulWidget {
  const OnboardingStage1({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  State<OnboardingStage1> createState() => _OnboardingStage1State();
}

class _OnboardingStage1State extends State<OnboardingStage1> {
  int _childCount = 1;
  final List<int?> _ages = List<int?>.filled(4, null);

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
            padding: const EdgeInsets.fromLTRB(30, 15, 30, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
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
                  child: const LinearProgressIndicator(
                    value: 0.385,
                    minHeight: 6,
                    backgroundColor: Color(0xFFECECEC),
                    valueColor: AlwaysStoppedAnimation(Color(0xFF48DA8C)),
                  ),
                ),
                const SizedBox(height: 35),
                Text(
                  'How many children are you\nhomeschooling?',
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
                  "Tell us how many learners you'll be "
                  'managing so we can create a space for each '
                  'child.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF525252),
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 35),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final count = index + 1;
                    final isSelected = _childCount == count;
                    return Padding(
                      padding: EdgeInsets.only(right: index == 3 ? 0 : 12),
                      child: SizedBox(
                        width: 64,
                        height: 66,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _childCount = count),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: isSelected
                                ? const Color(0xFF3159AA)
                                : Colors.white,
                            foregroundColor: isSelected
                                ? Colors.white
                                : const Color(0xFF7A7A7A),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF3159AA)
                                  : const Color(0xFFD9D9D9),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.nunito(
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 26),
                _buildAgeFields(),
                const Spacer(),
                Text(
                  "Your child's privacy matters.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF737373),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  'Class Mates is designed to collect only the information '
                  "it needs. We don't ask for children's names—just their "
                  'age, so we can personalise the app while helping '
                  'protect their privacy.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF737373),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 51,
                  child: FilledButton(
                    onPressed: () {
                      if (widget.onContinue case final callback?) {
                        callback();
                        return;
                      }

                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const OnboardingStage12(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00A94F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
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
    );
  }

  Widget _buildAgeFields() {
    if (_childCount == 1) {
      return _ageField(0);
    }

    if (_childCount == 2) {
      return Column(
        children: [_ageField(0), const SizedBox(height: 24), _ageField(1)],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ageField(0)),
            const SizedBox(width: 10),
            Expanded(child: _ageField(1)),
          ],
        ),
        if (_childCount > 2) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ageField(2)),
              const SizedBox(width: 10),
              Expanded(
                child: _childCount == 4
                    ? _ageField(3)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _ageField(int index) {
    return _ChildAgeField(
      childNumber: index + 1,
      age: _ages[index],
      onAgeSelected: (age) => setState(() => _ages[index] = age),
    );
  }
}

class _ChildAgeField extends StatelessWidget {
  const _ChildAgeField({
    required this.childNumber,
    required this.age,
    required this.onAgeSelected,
  });

  final int childNumber;
  final int? age;
  final ValueChanged<int> onAgeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD4D4D4)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Child $childNumber',
              style: GoogleFonts.nunito(
                color: const Color(0xFF525252),
                fontSize: 18,
              ),
            ),
          ),
          PopupMenuButton<int>(
            initialValue: age,
            onSelected: onAgeSelected,
            position: PopupMenuPosition.under,
            tooltip: 'Select child age',
            itemBuilder: (_) => List.generate(17, (index) {
              final value = index + 2;
              return PopupMenuItem(value: value, child: Text('$value years'));
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
              child: Text(
                age == null ? 'Select age' : '$age years',
                style: GoogleFonts.nunito(
                  color: const Color(0xFF008A3F),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
