import 'package:flutter/cupertino.dart';
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
                      style: GoogleFonts.lato(
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
                  style: GoogleFonts.lato(
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
                  style: GoogleFonts.lato(
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
                            style: GoogleFonts.lato(
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
                  style: GoogleFonts.lato(
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
                  style: GoogleFonts.lato(
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
                    onPressed:
                        _ages.take(_childCount).every((age) => age != null)
                        ? () {
                            if (widget.onContinue case final callback?) {
                              callback();
                              return;
                            }

                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => OnboardingStage12(
                                  childCount: _childCount,
                                  childAges: _ages.take(_childCount).toList(),
                                ),
                              ),
                            );
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00A94F),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFB7B7B7),
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

  static const _ageOptions = <(int, String)>[
    (5, 'Primary - Age 5'),
    (6, 'Primary - Age 6'),
    (7, 'Primary - Age 7'),
    (8, 'Primary - Age 8'),
    (9, 'Primary - Age 9'),
    (10, 'Primary - Age 10'),
    (11, 'Year 7 - Age 11-12'),
    (12, 'Year 8 - Age 12-13'),
    (13, 'Year 9 - Age 13-14'),
    (14, 'Year 10 - Age 14-15'),
    (15, 'Year 11 - Age 15-16'),
  ];

  String? get _selectedLabel {
    if (age == null) return null;
    for (final option in _ageOptions) {
      if (option.$1 == age) return option.$2;
    }
    return '$age years';
  }

  Future<void> _selectAge(BuildContext context) async {
    var selectedIndex = age == null
        ? 0
        : _ageOptions
              .indexWhere((option) => option.$1 == age)
              .clamp(0, _ageOptions.length - 1);
    final selectedAge = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: 285,
          child: Column(
            children: [
              SizedBox(
                height: 54,
                child: Row(
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      onPressed: () => Navigator.pop(
                        sheetContext,
                        _ageOptions[selectedIndex].$1,
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 38,
                  scrollController: FixedExtentScrollController(
                    initialItem: selectedIndex,
                  ),
                  onSelectedItemChanged: (index) => selectedIndex = index,
                  children: _ageOptions
                      .map((option) => Center(child: Text(option.$2)))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selectedAge != null) onAgeSelected(selectedAge);
  }

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
              style: GoogleFonts.lato(
                color: const Color(0xFF525252),
                fontSize: 18,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Select age for Child $childNumber',
            child: InkWell(
              onTap: () => _selectAge(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 12,
                ),
                child: Text(
                  _selectedLabel ?? 'Select age',
                  style: GoogleFonts.lato(
                    color: const Color(0xFF008A3F),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
