import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/message_widget.dart';

class SubjectProgressScreen extends StatefulWidget {
  const SubjectProgressScreen({
    super.key,
    required this.subject,
    required this.childNumber,
    this.entryId,
  });
  final String subject;
  final int childNumber;
  final String? entryId;
  @override
  State<SubjectProgressScreen> createState() => _SubjectProgressScreenState();
}

class _SubjectProgressScreenState extends State<SubjectProgressScreen> {
  static const green = Color(0xFF00AD4D);
  String? _levelId;
  String? _expanded;
  Map<String, String> _statuses = {};
  bool _loading = true;
  bool _progressDocumentExists = false;
  String _englishTrack = 'Language';
  String _pathway = 'GCSE';

  DocumentReference<Map<String, dynamic>>? get _document {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.entryId == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('subjectProgress')
        .doc(widget.entryId);
  }

  bool get _isSupported =>
      widget.subject == 'Mathematics' ||
      widget.subject == 'English' ||
      widget.subject == 'Science';

  Map<String, Level> get _subjectLevels => switch (widget.subject) {
    'English' when _pathway == 'GCSE' && _englishTrack == 'Literature' => {
      ...englishLevels,
      ...englishLiteratureLevels,
    },
    'English' => englishLevels,
    'Science' => scienceLevels,
    _ => mathsLevels,
  };

  Level? get _level =>
      _isSupported && _levelId != null ? _subjectLevels[_levelId] : null;

  bool get _showEnglishTrack =>
      widget.subject == 'English' &&
      (_levelId?.startsWith('year') ?? false) &&
      _pathway == 'GCSE';

  List<(String, String)> get _availableStartingPoints => startingPoints
      .where((point) => _subjectLevels.containsKey(point.$1))
      .toList();

  String get _levelLabel => startingPoints
      .firstWhere(
        (point) => point.$1 == _levelId,
        orElse: () => (_levelId ?? '', _level?.label ?? ''),
      )
      .$2;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final results = await Future.wait([
        if (_document case final document?) document.get(),
        if (user != null)
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      ]);
      final snapshot = results.firstOrNull;
      final data = snapshot?.data();
      _progressDocumentExists = snapshot?.exists == true;
      _levelId = data?['startingPointId'] as String?;
      if (_levelId == 'age11') _levelId = 'year7';
      final englishTrack = data?['englishTrack'];
      if (englishTrack == 'Language' || englishTrack == 'Literature') {
        _englishTrack = englishTrack as String;
      }
      final pathway = data?['curriculumPathway'];
      if (pathway == 'Flexible' || pathway == 'GCSE') {
        _pathway = pathway as String;
      }
      final statuses = data?['topicStatuses'];
      if (statuses is Map) {
        _statuses = statuses.map((key, value) => MapEntry('$key', '$value'));
      }
      if (_levelId == null && user != null && results.isNotEmpty) {
        final profile = results.last.data();
        final ages = profile?['childAges'];
        final index = widget.childNumber - 1;
        if (ages is List && index >= 0 && index < ages.length) {
          final age = ages[index];
          if (age is num) _levelId = _levelIdForAge(age.toInt());
        }
      }
    } on FirebaseException {
      // Keep the content available offline and retry when the user changes it.
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _expanded = _level?.modules.firstOrNull?.name;
    });
  }

  Future<void> _save() async {
    final document = _document;
    if (document == null || _levelId == null) return;
    try {
      await document.set({
        'subject': widget.subject,
        'childNumber': widget.childNumber,
        'startingPointId': _levelId,
        'topicStatuses': _statuses,
        if (_levelId?.startsWith('year') ?? false)
          'curriculumPathway': _pathway,
        if (_showEnglishTrack) 'englishTrack': _englishTrack,
        if (!_progressDocumentExists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _progressDocumentExists = true;
      if (mounted) {
        showMessagePopup(
          context,
          message: 'Progress saved successfully.',
          duration: const Duration(seconds: 2),
        );
      }
    } on FirebaseException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[SubjectProgress] Save failed (${error.code}): ${error.message}',
        );
      }
      if (mounted) {
        showMessagePopup(
          context,
          message: 'Could not save this progress. Please try again.',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _pickLevel() async {
    final availablePoints = _availableStartingPoints;
    if (availablePoints.isEmpty) return;
    var selectedIndex = availablePoints
        .indexWhere((point) => point.$1 == _levelId)
        .clamp(0, availablePoints.length - 1);
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: 370,
          child: Column(
            children: [
              SizedBox(
                height: 56,
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
                        availablePoints[selectedIndex].$1,
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
                  children: availablePoints
                      .map((point) => Center(child: Text(point.$2)))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || result == _levelId || !mounted) return;
    setState(() {
      _levelId = result;
      _statuses = {};
      _expanded = _subjectLevels[result]?.modules.firstOrNull?.name;
    });
    await _save();
  }

  Future<void> _changeStatus(String topicId) async {
    const next = {
      'toDo': 'learning',
      'learning': 'complete',
      'complete': 'toDo',
    };
    setState(() => _statuses[topicId] = next[_statuses[topicId] ?? 'toDo']!);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leadingWidth: 96,
          leading: TextButton(
            onPressed: () => Navigator.maybePop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF333333),
              padding: const EdgeInsets.only(left: 12, right: 4),
              alignment: Alignment.centerLeft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chevron_left, size: 21),
                const SizedBox(width: 2),
                Text(
                  'Back',
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.lato(fontSize: 13),
                ),
              ],
            ),
          ),
          title: Text(
            widget.subject,
            style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          actions: [
            if (_showEnglishTrack)
              _EnglishTrackDropdown(
                value: _englishTrack,
                onChanged: (value) {
                  setState(() {
                    _englishTrack = value;
                    _expanded = _level?.modules.firstOrNull?.name;
                  });
                  _save();
                },
              ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFEAEAEA)),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: green))
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                children: !_isSupported
                    ? [
                        Padding(
                          padding: const EdgeInsets.only(top: 110),
                          child: Text(
                            '${widget.subject} learning topics are coming soon.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                              color: const Color(0xFF777777),
                            ),
                          ),
                        ),
                      ]
                    : level == null
                    ? [
                        Text(
                          'No age is saved for Child ${widget.childNumber}.',
                          style: GoogleFonts.lato(
                            color: const Color(0xFF777777),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildLevelSelector('Select an age or year'),
                      ]
                    : [
                        _buildLevelSelector(_levelLabel),
                        const SizedBox(height: 4),
                        Text(
                          '${level.modules.length} modules to explore throughout the year',
                          style: GoogleFonts.lato(
                            color: const Color(0xFF777777),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...level.modules.map(
                          (module) => _ModuleCard(
                            module: module,
                            expanded: _expanded == module.name,
                            statuses: _statuses,
                            onHeaderTap: () => setState(
                              () => _expanded = _expanded == module.name
                                  ? null
                                  : module.name,
                            ),
                            onTopicTap: _changeStatus,
                          ),
                        ),
                      ],
              ),
        bottomNavigationBar:
            _isSupported && (_levelId?.startsWith('year') ?? false)
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PathButton(
                        label: 'Flexible Pathway',
                        selected: _pathway == 'Flexible',
                        onPressed: () {
                          setState(() {
                            _pathway = 'Flexible';
                            _expanded = _level?.modules.firstOrNull?.name;
                          });
                          _save();
                        },
                      ),
                      const SizedBox(width: 12),
                      _PathButton(
                        label: 'GCSE Pathway',
                        selected: _pathway == 'GCSE',
                        onPressed: () {
                          setState(() {
                            _pathway = 'GCSE';
                            _expanded = _level?.modules.firstOrNull?.name;
                          });
                          _save();
                        },
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildLevelSelector(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: const Color(0xFFF4FBF7),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _pickLevel,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lato(
                    color: green,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, color: green, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _levelIdForAge(int age) {
  if (age <= 5) return 'age5';
  if (age <= 10) return 'age$age';
  if (age == 11) return 'year7';
  if (age == 12) return 'year8';
  if (age == 13) return 'year9';
  if (age == 14) return 'year10';
  return 'year11';
}

class _EnglishTrackDropdown extends StatelessWidget {
  const _EnglishTrackDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'Language', child: Text('Language')),
        PopupMenuItem(value: 'Literature', child: Text('Literature')),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.fromLTRB(14, 0, 9, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _SubjectProgressScreenState.green,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.lato(
                color: const Color(0xFF171717),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: _SubjectProgressScreenState.green,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.expanded,
    required this.statuses,
    required this.onHeaderTap,
    required this.onTopicTap,
  });
  final Module module;
  final bool expanded;
  final Map<String, String> statuses;
  final VoidCallback onHeaderTap;
  final ValueChanged<String> onTopicTap;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      border: Border.all(
        color: expanded
            ? _SubjectProgressScreenState.green
            : const Color(0xFFE1E1E1),
      ),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      children: [
        InkWell(
          onTap: onHeaderTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    module.name,
                    style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          ...module.topics.asMap().entries.map((entry) {
            final topic = entry.value;
            final id = '${module.name}/$topic';
            return Column(
              children: [
                InkWell(
                  onTap: () => onTopicTap(id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic,
                            style: GoogleFonts.lato(fontSize: 13),
                          ),
                        ),
                        _StatusBadge(status: statuses[id] ?? 'toDo'),
                      ],
                    ),
                  ),
                ),
                if (entry.key < module.topics.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 14,
                    endIndent: 14,
                    color: Color(0xFFE7E7E7),
                  ),
              ],
            );
          }),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final label = status == 'complete'
        ? 'Complete'
        : status == 'learning'
        ? 'Learning'
        : 'Explore';
    final color = status == 'complete'
        ? const Color(0xFF9145F5)
        : status == 'learning'
        ? _SubjectProgressScreenState.green
        : const Color(0xFFB8B8B8);
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PathButton extends StatelessWidget {
  const _PathButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      backgroundColor: selected
          ? _SubjectProgressScreenState.green
          : Colors.white,
      foregroundColor: selected ? Colors.white : const Color(0xFF171717),
      side: BorderSide(
        color: selected
            ? _SubjectProgressScreenState.green
            : const Color(0xFFE1E1E1),
      ),
      shape: const StadiumBorder(),
    ),
    child: Text(
      label,
      style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}

class Level {
  const Level(this.label, this.modules);
  final String label;
  final List<Module> modules;
}

class Module {
  const Module(this.name, this.topics);
  final String name;
  final List<String> topics;
}

const mathsPreviewModules = [
  Module('Number', [
    'Fractions',
    'Decimals',
    'Percentages',
    'Powers & Roots',
    'Factors and multiples',
  ]),
  Module('Algebra', [
    'Expressions and formulae',
    'Expanding and factorising',
    'Linear graphs',
  ]),
];

const mathsPreviewStatuses = <String, String>{
  'Number/Fractions': 'complete',
  'Number/Decimals': 'complete',
  'Number/Percentages': 'learning',
};

const englishPreviewModules = [
  Module('Reading', [
    'Word reading',
    'Reading fluency',
    'Vocabulary',
    'Comprehension',
    'Discussing texts',
  ]),
  Module('Writing', [
    'Spelling',
    'Handwriting',
    'Composition',
    'Grammar and punctuation',
  ]),
];

const englishPreviewStatuses = <String, String>{
  'Reading/Word reading': 'complete',
  'Reading/Reading fluency': 'complete',
  'Reading/Vocabulary': 'learning',
};

const startingPoints = <(String, String)>[
  ('age5', 'Primary — Age 5'),
  ('age6', 'Primary — Age 6'),
  ('age7', 'Primary — Age 7'),
  ('age8', 'Primary — Age 8'),
  ('age9', 'Primary — Age 9'),
  ('age10', 'Primary — Age 10'),
  ('year7', 'Year 7 — Age 11–12'),
  ('year8', 'Year 8 — Age 12–13'),
  ('year9', 'Year 9 — Age 13–14'),
  ('year10', 'Year 10 — Age 14–15'),
  ('year11', 'Year 11 — Age 15–16'),
];

const mathsLevels = <String, Level>{
  'age5': Level('Age 5', [
    Module('Numbers', [
      'Counting to 100',
      'Recognising numbers',
      'Writing numbers',
      'Ordering numbers',
      'One more and one less',
    ]),
    Module('Adding & Taking Away', [
      'Counting on',
      'Counting back',
      'Number bonds to 10',
      'Combining groups',
      'Finding how many are left',
    ]),
    Module('Groups & Fractions', [
      'Counting in 2s',
      'Counting in 5s',
      'Counting in 10s',
      'Sharing equally',
      'Finding halves and quarters',
    ]),
    Module('Shape & Measure', [
      '2D shapes',
      '3D shapes',
      'Position and direction',
      'Comparing length and height',
      'Comparing weight and capacity',
    ]),
    Module('Time, Money & Problems', [
      'Recognising coins',
      'Counting small amounts of money',
      'Days and months',
      'Reading the hour on a clock',
      'Solving everyday maths problems',
    ]),
  ]),
  'age6': Level('Age 6', [
    Module('Number & Place Value', [
      'Numbers to 100',
      'Tens and ones',
      'Comparing numbers',
      'Odd and even numbers',
      'Number patterns',
    ]),
    Module('Addition & Subtraction', [
      'Number bonds to 20',
      'Adding two-digit numbers',
      'Taking away two-digit numbers',
      'Using mental calculation strategies',
      'Solving one-step problems',
    ]),
    Module('Multiplication & Division', [
      'Multiplication as equal groups',
      'Using arrays',
      'Division as sharing',
      'Division as grouping',
      'Using 2, 5 and 10 times tables',
    ]),
    Module('Fractions, Shape & Measure', [
      'Finding halves of quantities',
      'Finding quarters of quantities',
      'Recognising thirds',
      'Describing properties of shapes',
      'Measuring in centimetres and metres',
    ]),
    Module('Time, Money & Data', [
      'Telling time to the hour',
      'Telling time to half past',
      'Finding totals with coins',
      'Finding simple change',
      'Reading simple tables and charts',
    ]),
  ]),
  'age7': Level('Age 7', [
    Module('Number & Place Value', [
      'Numbers to 1,000',
      'Hundreds, tens and ones',
      'Ordering larger numbers',
      'Rounding to the nearest 10',
      'Using number lines',
    ]),
    Module('Calculation', [
      'Adding three-digit numbers',
      'Subtracting three-digit numbers',
      'Using inverse operations',
      'Estimating answers',
      'Solving two-step problems',
    ]),
    Module('Multiplication, Division & Fractions', [
      '3, 4 and 8 times tables',
      'Applying multiplication facts',
      'Written multiplication',
      'Written division',
      'Finding fractions of amounts',
    ]),
    Module('Geometry & Measurement', [
      'Recognising right angles',
      'Describing angles',
      'Perimeter',
      'Area using squares',
      'Measuring in millimetres and centimetres',
    ]),
    Module('Time, Money & Data', [
      'Telling time to 5 minutes',
      'Reading digital clocks',
      'Calculating durations',
      'Using money and giving change',
      'Interpreting charts and tables',
    ]),
  ]),
  'age8': Level('Age 8', [
    Module('Number & Place Value', [
      'Numbers to 10,000',
      'Thousands, hundreds, tens and ones',
      'Rounding to the nearest 100',
      'Negative numbers',
      'Roman numerals',
    ]),
    Module('Written Calculation', [
      'Efficient written addition',
      'Efficient written subtraction',
      'Checking calculations',
      'Multiplying by 10 and 100',
      'Dividing by 10 and 100',
    ]),
    Module('Multiplication, Division & Fractions', [
      '6, 7, 9 and 11 times tables',
      'Factors and multiples',
      'Formal written multiplication',
      'Formal written division',
      'Equivalent fractions',
    ]),
    Module('Fractions, Decimals & Geometry', [
      'Comparing fractions',
      'Adding fractions with the same denominator',
      'Tenths as fractions and decimals',
      'Identifying angles greater than a right angle',
      'Classifying quadrilaterals and triangles',
    ]),
    Module('Measurement, Money & Data', [
      'Perimeter of rectilinear shapes',
      'Area of rectangles',
      'Converting simple units',
      'Solving money problems',
      'Interpreting bar charts and pictograms',
    ]),
  ]),
  'age9': Level('Age 9', [
    Module('Number & Calculation', [
      'Numbers to 100,000',
      'Rounding to the nearest 1,000',
      'Reading and writing large numbers',
      'Mental calculation strategies',
      'Solving multi-step calculations',
    ]),
    Module('Multiplication & Division', [
      'Multiplying by multiples of 10 and 100',
      'Short multiplication',
      'Short division',
      'Remainders in division',
      'Solving problems using factors and multiples',
    ]),
    Module('Fractions, Decimals & Percentages', [
      'Simplifying fractions',
      'Comparing fractions with different denominators',
      'Adding and subtracting fractions',
      'Hundredths as decimals',
      'Introducing percentages',
    ]),
    Module('Geometry, Measure & Coordinates', [
      'Measuring and comparing angles',
      'Angles in triangles and quadrilaterals',
      'Area of compound rectilinear shapes',
      'Coordinates in the first quadrant',
      'Converting between units',
    ]),
    Module('Ratio, Data & Problem Solving', [
      'Understanding simple ratio',
      'Scaling quantities',
      'Reading line graphs',
      'Finding averages',
      'Solving problems with multiple steps',
    ]),
  ]),
  'age10': Level('Age 10', [
    Module('Number & Place Value', [
      'Numbers to 1,000,000',
      'Powers of 10',
      'Rounding to different degrees of accuracy',
      'Prime numbers',
      'Square and cube numbers',
    ]),
    Module('Calculation & Problem Solving', [
      'Long multiplication',
      'Long division',
      'Interpreting remainders',
      'Order of operations',
      'Multi-step reasoning problems',
    ]),
    Module('Fractions, Decimals & Percentages', [
      'Multiplying fractions',
      'Dividing fractions by whole numbers',
      'Converting fractions, decimals and percentages',
      'Calculating percentages of amounts',
      'Solving percentage problems',
    ]),
    Module('Ratio, Algebra & Geometry', [
      'Using ratio to compare quantities',
      'Solving scaling problems',
      'Using simple algebraic expressions',
      'Coordinates in four quadrants',
      'Calculating volume',
    ]),
    Module('Measures, Data & Reasoning', [
      'Converting between metric units',
      'Calculating area of triangles',
      'Calculating area of parallelograms',
      'Interpreting pie charts',
      'Solving complex real-world problems',
    ]),
  ]),
  'age11': Level('Age 11', [
    Module('Number', [
      'Integers and place value',
      'Four operations',
      'Factors, multiples and primes',
      'Fractions and percentages',
    ]),
    Module('Ratio & Algebra', [
      'Ratio notation',
      'Direct proportion',
      'Using formulae',
      'One-step equations',
    ]),
    Module('Geometry & Measure', [
      'Angles and constructions',
      'Area and volume',
      'Transformations',
      'Units of measure',
    ]),
    Module('Statistics', [
      'Averages and range',
      'Tables and charts',
      'Probability scale',
    ]),
  ]),
  'year7': Level('Year 7 - Age 11–12', [
    Module('Number', [
      'Integers & Place Value',
      'Fractions, Decimals & Percentages',
      'Factors & Multiples',
      'Powers & Roots',
      'Ratio & Proportion',
    ]),
    Module('Algebra', [
      'Algebraic Expressions',
      'Simplifying & Substitution',
      'Linear Equations',
      'Sequences',
      'Coordinates',
    ]),
    Module('Geometry', [
      'Angles & Lines',
      'Triangles & Quadrilaterals',
      'Polygons',
      'Perimeter & Area',
      'Transformations',
    ]),
    Module('Measures', [
      'Units & Conversions',
      'Area & Volume',
      'Time & Timetables',
      'Scale Drawings',
      'Compound Measures',
    ]),
    Module('Statistics & Probability', [
      'Collecting Data',
      'Tables & Charts',
      'Averages',
      'Probability',
      'Interpreting Data',
    ]),
  ]),
  'year8': Level('Year 8 - Age 12–13', [
    Module('Number', [
      'Fractions & Percentages',
      'Ratio & Proportion',
      'Powers & Roots',
      'Standard Form',
      'Estimation & Approximation',
    ]),
    Module('Algebra', [
      'Expanding & Simplifying',
      'Linear Equations',
      'Inequalities',
      'Sequences',
      'Linear Graphs',
    ]),
    Module('Geometry', [
      'Angle Rules',
      'Polygons',
      'Constructions & Loci',
      'Transformations',
      'Congruence',
    ]),
    Module('Measures', [
      'Area of 2D Shapes',
      'Volume',
      'Surface Area',
      'Circles',
      'Scale & Similarity',
    ]),
    Module('Statistics & Probability', [
      'Data Representation',
      'Averages & Range',
      'Scatter Graphs',
      'Probability Experiments',
      'Comparing Data',
    ]),
  ]),
  'year9': Level('Year 9 - Age 13–14', [
    Module('Number', [
      'Standard Form',
      'Recurring Decimals',
      'Percentage Change',
      'Ratio & Proportion',
      'Indices',
    ]),
    Module('Algebra', [
      'Algebraic Manipulation',
      'Simultaneous Equations',
      'Quadratic Expressions',
      'Sequences',
      'Inequalities',
    ]),
    Module('Geometry', [
      "Pythagoras' Theorem",
      'Trigonometry',
      'Similarity',
      'Circle Geometry',
      'Vectors',
    ]),
    Module('Graphs & Functions', [
      'Linear Graphs',
      'Quadratic Graphs',
      'Real-Life Graphs',
      'Functions',
      'Rates of Change',
    ]),
    Module('Statistics & Probability', [
      'Sampling',
      'Statistical Diagrams',
      'Averages & Spread',
      'Probability Trees',
      'Expected Outcomes',
    ]),
  ]),
  'year10': Level('Year 10 - Age 14–15', [
    Module('Number', [
      'Surds',
      'Indices',
      'Compound Interest',
      'Direct & Inverse Proportion',
      'Bounds & Error',
    ]),
    Module('Algebra', [
      'Quadratic Equations',
      'Factorising',
      'Completing the Square',
      'Algebraic Fractions',
      'Iteration',
    ]),
    Module('Geometry & Trigonometry', [
      'Sine & Cosine Rules',
      'Circle Theorems',
      'Advanced Trigonometry',
      'Vectors',
      'Similarity & Enlargement',
    ]),
    Module('Graphs & Functions', [
      'Quadratic Graphs',
      'Cubic & Reciprocal Graphs',
      'Functions & Inverses',
      'Graph Transformations',
      'Gradients & Rates of Change',
    ]),
    Module('Statistics & Probability', [
      'Histograms',
      'Cumulative Frequency',
      'Box Plots',
      'Conditional Probability',
      'Statistical Distributions',
    ]),
  ]),
  'year11': Level('Year 11 - Age 15–16', [
    Module('Number & Proportion', [
      'Exact Calculations',
      'Advanced Ratio & Proportion',
      'Bounds & Accuracy',
      'Numerical Methods',
      'Financial Mathematics',
    ]),
    Module('Algebra', [
      'Algebraic Proof',
      'Functions',
      'Equations & Inequalities',
      'Sequences',
      'Mathematical Modelling',
    ]),
    Module('Geometry & Measures', [
      'Circle Theorems',
      'Advanced Trigonometry',
      'Vectors',
      'Similarity & Congruence',
      '3D Geometry',
    ]),
    Module('Statistics & Probability', [
      'Cumulative Frequency',
      'Histograms',
      'Box Plots',
      'Conditional Probability',
      'Data Interpretation',
    ]),
    Module('Problem Solving', [
      'Multi-Step Problems',
      'Mathematical Reasoning',
      'Real-World Problems',
      'Problem-Solving Strategies',
      'Mathematical Communication',
    ]),
  ]),
};

const englishLevels = <String, Level>{
  'age5': Level('Age 5', [
    Module('Phonics & Sounds', [
      'Recognising letter sounds',
      'Blending sounds',
      'Segmenting words',
      'Reading simple words',
      'Spelling simple words',
    ]),
    Module('Early Reading', [
      'Reading simple sentences',
      'Recognising common words',
      'Reading aloud',
      "Understanding what you've read",
      'Talking about stories',
    ]),
    Module('Early Writing', [
      'Forming letters',
      'Writing words',
      'Writing simple sentences',
      'Using capital letters',
      'Using full stops',
    ]),
    Module('Stories & Imagination', [
      'Listening to stories',
      'Characters',
      'Settings',
      'Retelling a story',
      'Creating simple stories',
    ]),
    Module('Speaking & Vocabulary', [
      'Speaking clearly',
      'Listening to others',
      'Learning new words',
      'Describing things',
      'Sharing ideas',
    ]),
  ]),
  'age6': Level('Age 6', [
    Module('Reading Skills', [
      'Reading independently',
      'Reading unfamiliar words',
      'Understanding sentences',
      'Finding information',
      'Predicting what happens next',
    ]),
    Module('Writing Skills', [
      'Writing complete sentences',
      'Using capital letters and punctuation',
      'Joining ideas',
      'Describing people and places',
      'Writing short stories',
    ]),
    Module('Grammar & Spelling', [
      'Nouns and verbs',
      'Adjectives',
      'Past and present tense',
      'Common spelling patterns',
      'Using commas',
    ]),
    Module('Stories & Books', [
      'Exploring characters',
      'Exploring settings',
      'Retelling stories',
      'Comparing stories',
      'Responding to books',
    ]),
    Module('Speaking & Communication', [
      'Asking questions',
      'Giving explanations',
      'Listening carefully',
      'Expressing opinions',
      'Speaking to an audience',
    ]),
  ]),
  'age7': Level('Age 7', [
    Module('Reading & Understanding', [
      'Reading longer texts',
      'Finding key information',
      'Making predictions',
      'Making simple inferences',
      "Summarising what you've read",
    ]),
    Module('Writing', [
      'Paragraphs',
      'Descriptive writing',
      'Narrative writing',
      'Writing instructions',
      'Editing your work',
    ]),
    Module('Grammar & Vocabulary', [
      'Adverbs',
      'Conjunctions',
      'Sentence structures',
      'Apostrophes',
      'Expanding vocabulary',
    ]),
    Module('Stories & Poetry', [
      'Character development',
      'Story structure',
      'Exploring themes',
      'Reading poetry',
      'Writing poetry',
    ]),
    Module('Communication', [
      'Presenting ideas',
      'Asking and answering questions',
      'Group discussions',
      'Giving opinions',
      'Adapting how you speak',
    ]),
  ]),
  'age8': Level('Age 8', [
    Module('Reading & Inference', [
      'Reading between the lines',
      'Using evidence from texts',
      'Identifying viewpoints',
      'Summarising information',
      'Comparing texts',
    ]),
    Module('Creative Writing', [
      'Building characters',
      'Creating settings',
      'Narrative structure',
      'Using descriptive language',
      'Improving your writing',
    ]),
    Module('Grammar & Language', [
      'Sentence structures',
      'Direct speech',
      'Paragraph organisation',
      'Vocabulary choices',
      'Punctuation for effect',
    ]),
    Module('Poetry & Literature', [
      'Exploring poems',
      'Imagery',
      'Rhyme and rhythm',
      'Comparing poems',
      'Responding to literature',
    ]),
    Module('Non-Fiction & Communication', [
      'Information texts',
      'Persuasive writing',
      'Letters and emails',
      'Presentations',
      'Debates and discussions',
    ]),
  ]),
  'age9': Level('Age 9', [
    Module('Reading Critically', [
      'Identifying themes',
      'Exploring characters',
      'Analysing language',
      'Comparing viewpoints',
      'Supporting ideas with evidence',
    ]),
    Module('Writing Effectively', [
      'Planning longer pieces',
      'Developing paragraphs',
      'Creating atmosphere',
      'Writing persuasively',
      'Editing and improving',
    ]),
    Module('Language & Grammar', [
      'Complex sentences',
      'Word classes',
      'Formal and informal language',
      'Punctuation choices',
      'Vocabulary and tone',
    ]),
    Module('Literature & Poetry', [
      'Exploring literary themes',
      'Analysing poems',
      'Comparing characters',
      "Exploring the writer's choices",
      'Giving personal responses',
    ]),
    Module('Non-Fiction & Speaking', [
      'Articles',
      'Reports',
      'Speeches',
      'Presenting arguments',
      'Evaluating information',
    ]),
  ]),
  'age10': Level('Age 10', [
    Module('Reading Analysis', [
      'Analysing language',
      'Analysing structure',
      'Exploring themes',
      'Comparing texts',
      'Building interpretations',
    ]),
    Module('Writing with Purpose', [
      'Narrative writing',
      'Descriptive writing',
      'Persuasive writing',
      'Formal writing',
      'Structuring extended responses',
    ]),
    Module('Language & Accuracy', [
      'Complex grammar',
      'Sentence variety',
      'Precise vocabulary',
      'Punctuation for effect',
      'Proofreading and editing',
    ]),
    Module('Literature', [
      'Analysing characters',
      'Analysing themes',
      'Exploring poetry',
      'Comparing texts',
      "Discussing the writer's intentions",
    ]),
    Module('Communication & Research', [
      'Researching information',
      'Evaluating sources',
      'Presenting findings',
      'Debating ideas',
      'Speaking confidently',
    ]),
  ]),
  'age11': Level('Age 11', [
    Module('Reading', [
      'Close reading',
      'Using textual evidence',
      'Comparing writers’ ideas',
      'Evaluating a text',
    ]),
    Module('Writing', [
      'Structured arguments',
      'Narrative techniques',
      'Accurate paragraphing',
      'Editing independently',
    ]),
    Module('Spoken English', [
      'Presenting ideas',
      'Responding to questions',
      'Participating in discussion',
    ]),
  ]),
  'year7': Level('Year 7 - Age 11–12', [
    Module('Reading & Understanding', [
      'Understanding Fiction & Non-Fiction',
      'Retrieving Information',
      'Inference',
      'Summarising',
      'Using Evidence',
    ]),
    Module('Language', [
      'Vocabulary',
      'Figurative Language',
      'Word Choice',
      'Sentence Types',
      'Language Effects',
    ]),
    Module('Creative Writing', [
      'Description',
      'Narrative',
      'Character',
      'Setting',
      'Dialogue',
    ]),
    Module('Writing Skills', [
      'Audience & Purpose',
      'Paragraphing',
      'Sentence Structure',
      'Planning',
      'Editing',
    ]),
    Module('Grammar & Communication', [
      'Spelling',
      'Punctuation',
      'Grammar',
      'Standard English',
      'Speaking & Listening',
    ]),
  ]),
  'year8': Level('Year 8 - Age 12–13', [
    Module('Reading & Analysis', [
      'Explicit & Implicit Meaning',
      'Inference & Interpretation',
      'Evidence',
      "Writer's Ideas",
      'Reader Response',
    ]),
    Module('Language & Structure', [
      'Language Techniques',
      'Structural Techniques',
      'Narrative Perspective',
      'Openings & Endings',
      'Effects on the Reader',
    ]),
    Module('Creative Writing', [
      'Narrative Structure',
      'Characterisation',
      'Description',
      'Imagery',
      'Atmosphere',
    ]),
    Module('Non-Fiction Writing', [
      'Articles',
      'Speeches',
      'Letters',
      'Reviews',
      'Informative Writing',
    ]),
    Module('Developing Writing', [
      'Sentence Variety',
      'Paragraph Cohesion',
      'Vocabulary',
      'Punctuation for Effect',
      'Editing & Redrafting',
    ]),
  ]),
  'year9': Level('Year 9 - Age 13–14', [
    Module('Critical Reading', [
      'Language Analysis',
      'Structure Analysis',
      "Writer's Methods",
      'Inference & Interpretation',
      'Evaluation',
    ]),
    Module('Comparing Texts', [
      'Viewpoints',
      'Ideas & Themes',
      'Language',
      'Structure',
      'Supporting Evidence',
    ]),
    Module('Creative Writing', [
      'Narrative Voice',
      'Character Development',
      'Setting',
      'Figurative Language',
      'Narrative Structure',
    ]),
    Module('Persuasive Writing', [
      'Persuasive Techniques',
      'Rhetorical Devices',
      'Articles & Blogs',
      'Speeches',
      'Building Arguments',
    ]),
    Module('Developing Style', [
      'Sentence Structures',
      'Cohesion',
      'Vocabulary & Register',
      'Punctuation for Effect',
      'Redrafting & Refinement',
    ]),
  ]),
  'year10': Level('Year 10 - Age 14–15', [
    Module('Advanced Reading', [
      'Critical Reading',
      'Language Analysis',
      'Structural Analysis',
      "Writer's Methods",
      'Evaluating Texts',
    ]),
    Module('Perspectives & Ideas', [
      'Identifying Perspectives',
      'Comparing Viewpoints',
      'Comparing Methods',
      'Evidence & Interpretation',
      'Evaluating Arguments',
    ]),
    Module('Creative Writing', [
      'Narrative Voice',
      'Characterisation',
      'Description',
      'Structure & Pacing',
      'Writing from a Stimulus',
    ]),
    Module('Transactional Writing', [
      'Audience & Purpose',
      'Articles & Essays',
      'Speeches',
      'Letters & Reviews',
      'Argument & Persuasion',
    ]),
    Module('Writing Craft', [
      'Sentence Control',
      'Vocabulary & Register',
      'Paragraph Structure',
      'Grammar & Punctuation',
      'Editing for Impact',
    ]),
  ]),
  'year11': Level('Year 11 - Age 15–16', [
    Module('Advanced Reading', [
      'Critical Analysis',
      'Language & Structure',
      'Inference & Interpretation',
      'Comparing Texts',
      'Evaluation',
    ]),
    Module('Creative Writing', [
      'Narrative Writing',
      'Descriptive Writing',
      'Character & Voice',
      'Structure & Atmosphere',
      'Developing a Personal Style',
    ]),
    Module('Perspectives & Arguments', [
      'Analysing Viewpoints',
      'Comparing Perspectives',
      "Writer's Methods",
      'Evidence & Evaluation',
      'Developing Your Own Viewpoint',
    ]),
    Module('Purposeful Writing', [
      'Audience & Purpose',
      'Argument & Persuasion',
      'Rhetorical Devices',
      'Formal Writing',
      'Informal & Personal Writing',
    ]),
    Module('Communication & Accuracy', [
      'Advanced Sentence Construction',
      'Vocabulary & Register',
      'Grammar',
      'Punctuation',
      'Editing & Proofreading',
    ]),
  ]),
};

const englishLiteratureLevels = <String, Level>{
  'year7': Level('Year 7 - Age 11–12', [
    Module('Reading Literature', [
      'Understanding Characters',
      'Setting',
      'Plot & Narrative',
      'Themes',
      'Using Evidence',
    ]),
    Module('Poetry', [
      'Reading Poetry',
      'Imagery',
      'Rhyme & Rhythm',
      'Poetic Language',
      'Comparing Poems',
    ]),
    Module('Prose', [
      'Short Stories',
      'Novels',
      'Character Development',
      'Narrative Voice',
      'Themes & Ideas',
    ]),
    Module('Drama', [
      'Reading Plays',
      'Characters & Relationships',
      'Dialogue',
      'Stage Directions',
      'Performance',
    ]),
    Module('Literary Skills', [
      'Literary Vocabulary',
      'Analysing Quotations',
      'Making Inferences',
      'Explaining Effects',
      'Building Arguments',
    ]),
  ]),
  'year8': Level('Year 8 - Age 12–13', [
    Module('Literary Analysis', [
      'Characterisation',
      'Themes',
      'Setting & Atmosphere',
      'Narrative Structure',
      "Writer's Intentions",
    ]),
    Module('Poetry', [
      'Metaphor & Symbolism',
      'Form & Structure',
      'Sound & Rhythm',
      'Tone & Mood',
      'Comparing Poems',
    ]),
    Module('Prose', [
      'Narrative Perspective',
      'Character Relationships',
      'Conflict',
      'Themes & Motifs',
      'Context',
    ]),
    Module('Drama', [
      'Dramatic Structure',
      'Characterisation',
      'Relationships',
      'Language & Dialogue',
      'Stagecraft',
    ]),
    Module('Developing Analysis', [
      'Selecting Quotations',
      'Analysing Language',
      'Analysing Structure',
      'Exploring Themes',
      'Developing Interpretations',
    ]),
  ]),
  'year9': Level('Year 9 - Age 13–14', [
    Module('Literary Analysis', [
      "Writer's Methods",
      'Character & Perspective',
      'Themes & Motifs',
      'Structure',
      'Alternative Interpretations',
    ]),
    Module('Poetry', [
      'Poetic Form',
      'Imagery & Symbolism',
      'Language & Tone',
      'Structure & Rhythm',
      'Comparative Analysis',
    ]),
    Module('Shakespeare', [
      'Characters',
      'Themes',
      'Language',
      'Dramatic Structure',
      'Context',
    ]),
    Module('Prose & Drama', [
      'Character Development',
      'Relationships',
      'Conflict',
      'Social & Historical Context',
      "Writer's Ideas",
    ]),
    Module('Critical Reading', [
      'Close Analysis',
      'Supporting Interpretations',
      'Exploring Ambiguity',
      'Contextual Understanding',
      'Critical Arguments',
    ]),
  ]),
  'year10': Level('Year 10 - Age 14–15', [
    Module('Shakespeare', [
      'Characterisation',
      'Themes',
      'Language & Imagery',
      'Structure & Dramatic Methods',
      'Context & Interpretations',
    ]),
    Module('19th-Century Prose', [
      'Characters',
      'Themes',
      'Setting',
      'Narrative Methods',
      'Social & Historical Context',
    ]),
    Module('Modern Prose & Drama', [
      'Character & Relationships',
      'Themes & Ideas',
      'Language',
      'Structure',
      'Context',
    ]),
    Module('Poetry', [
      'Poetic Methods',
      'Form & Structure',
      'Language & Imagery',
      'Tone & Perspective',
      'Comparing Poems',
    ]),
    Module('GCSE Literary Analysis', [
      'Selecting Evidence',
      'Close Language Analysis',
      "Writer's Methods",
      'Context',
      'Developing Critical Arguments',
    ]),
  ]),
  'year11': Level('Year 11 - Age 15–16', [
    Module('Shakespeare', [
      'Character & Relationships',
      'Themes & Ideas',
      'Language Analysis',
      'Dramatic Methods',
      'Context & Interpretations',
    ]),
    Module('19th-Century Prose', [
      'Characterisation',
      'Themes',
      'Narrative Structure',
      'Language & Methods',
      'Context & Interpretations',
    ]),
    Module('Modern Prose & Drama', [
      'Characters & Relationships',
      'Themes & Messages',
      'Language & Structure',
      "Writer's Methods",
      'Context',
    ]),
    Module('Poetry Comparison', [
      'Comparing Themes',
      'Comparing Language',
      'Comparing Structure',
      'Comparing Perspectives',
      'Comparative Arguments',
    ]),
    Module('GCSE Exam Skills', [
      'Planning Essays',
      'Selecting Quotations',
      'Developing Interpretations',
      'Integrating Context',
      'Writing Critical Essays',
    ]),
  ]),
};

const scienceLevels = <String, Level>{
  'age5': Level('Age 5', [
    Module('Living Things', [
      'Animals',
      'Plants',
      'Humans',
      'Senses',
      'Living and non-living things',
    ]),
    Module('Our World', [
      'Weather',
      'Seasons',
      'Day and night',
      'Light and dark',
      'Materials around us',
    ]),
    Module('Materials', [
      'Solids and liquids',
      'Hard and soft',
      'Rough and smooth',
      'Changing materials',
      'Choosing materials',
    ]),
    Module('Plants & Nature', [
      'Parts of a plant',
      'What plants need',
      'Growing seeds',
      'Flowers and trees',
      'Nature around us',
    ]),
    Module('Exploring & Experiments', [
      'Observing',
      'Sorting and grouping',
      'Measuring',
      'Making predictions',
      'Simple investigations',
    ]),
  ]),
  'age6': Level('Age 6', [
    Module('Animals & Humans', [
      'Animal groups',
      'Animal habitats',
      'Human body',
      'Healthy eating',
      'Exercise and movement',
    ]),
    Module('Plants', [
      'Plant parts',
      'Roots, stems and leaves',
      'What plants need',
      'Seeds and growth',
      'Plant life cycles',
    ]),
    Module('Materials', [
      'Solids, liquids and gases',
      'Properties of materials',
      'Changing materials',
      'Reversible changes',
      'Choosing materials for a purpose',
    ]),
    Module('Earth & Space', [
      'Our planet',
      'The Sun',
      'The Moon',
      'Day and night',
      'Seasons',
    ]),
    Module('Forces & Investigation', [
      'Pushes and pulls',
      'Movement',
      'Magnets',
      'Making predictions',
      'Recording results',
    ]),
  ]),
  'age7': Level('Age 7', [
    Module('Living Things', [
      'Life processes',
      'Animal groups',
      'Food chains',
      'Habitats',
      'Adaptation',
    ]),
    Module('Plants & Ecosystems', [
      'Plant reproduction',
      'Pollination',
      'Seeds and dispersal',
      'Plant life cycles',
      'Ecosystems',
    ]),
    Module('Forces & Energy', [
      'Forces',
      'Friction',
      'Magnets',
      'Light',
      'Shadows',
    ]),
    Module('Rocks & Earth', [
      'Types of rocks',
      'Fossils',
      'Soils',
      'The rock cycle',
      'Erosion',
    ]),
    Module('Scientific Investigation', [
      'Asking scientific questions',
      'Making predictions',
      'Fair tests',
      'Measuring and recording',
      'Drawing conclusions',
    ]),
  ]),
  'age8': Level('Age 8', [
    Module('Humans & Animals', [
      'Skeletons',
      'Muscles',
      'Digestion',
      'Teeth',
      'Healthy bodies',
    ]),
    Module('Living Things & Habitats', [
      'Classification',
      'Food chains',
      'Food webs',
      'Habitats',
      'Environmental change',
    ]),
    Module('Electricity & Energy', [
      'Electrical circuits',
      'Conductors and insulators',
      'Switches',
      'Renewable energy',
      'Energy transfer',
    ]),
    Module('Light, Sound & Forces', [
      'How light travels',
      'Reflection',
      'Sound',
      'Vibrations',
      'Forces and movement',
    ]),
    Module('Earth & Space', [
      'The solar system',
      'Planets',
      'The Moon',
      "Earth's rotation",
      "Earth's orbit",
    ]),
  ]),
  'age9': Level('Age 9', [
    Module('Biology', [
      'Cells',
      'Organs',
      'Life cycles',
      'Reproduction',
      'Classification',
    ]),
    Module('Ecosystems', [
      'Food chains',
      'Food webs',
      'Producers and consumers',
      'Adaptation',
      'Human impact',
    ]),
    Module('Chemistry', [
      'States of matter',
      'Particles',
      'Dissolving',
      'Mixtures',
      'Separating materials',
    ]),
    Module('Physics', ['Forces', 'Gravity', 'Friction', 'Light', 'Sound']),
    Module('Earth & Space', [
      'The solar system',
      "Earth's structure",
      'Rocks and minerals',
      'Water cycle',
      'Climate and weather',
    ]),
  ]),
  'age10': Level('Age 10', [
    Module('Biology', [
      'Cells and microscopes',
      'Organ systems',
      'Reproduction',
      'Variation',
      'Adaptation and evolution',
    ]),
    Module('Ecology', [
      'Ecosystems',
      'Food webs',
      'Interdependence',
      'Biodiversity',
      'Conservation',
    ]),
    Module('Chemistry', [
      'Atoms and particles',
      'Elements',
      'Compounds',
      'Chemical reactions',
      'Acids and alkalis',
    ]),
    Module('Physics', [
      'Forces and motion',
      'Gravity',
      'Electricity',
      'Energy',
      'Light and sound',
    ]),
    Module('Earth & Scientific Skills', [
      "Earth's structure",
      'The atmosphere',
      'Climate change',
      'Scientific experiments',
      'Analysing and presenting data',
    ]),
  ]),
  'year7': Level('Year 7 - Age 11–12', [
    Module('Working Scientifically', [
      'Laboratory Safety',
      'Scientific Investigations',
      'Variables & Fair Tests',
      'Measuring & Recording Data',
      'Tables & Graphs',
    ]),
    Module('Biology — Cells & Living Things', [
      'Animal & Plant Cells',
      'Specialised Cells',
      'Microscopes',
      'Tissues & Organs',
      'Organ Systems',
    ]),
    Module('Chemistry — Matter', [
      'States of Matter',
      'Particle Model',
      'Elements',
      'Compounds',
      'Separating Mixtures',
    ]),
    Module('Physics — Forces & Energy', [
      'Forces',
      'Gravity & Weight',
      'Speed & Motion',
      'Energy Stores',
      'Energy Transfers',
    ]),
    Module('Biology — Ecosystems', [
      'Habitats',
      'Food Chains',
      'Food Webs',
      'Adaptation',
      'Human Impact',
    ]),
  ]),
  'year8': Level('Year 8 - Age 12–13', [
    Module('Biology — Human Biology', [
      'Nutrition',
      'Digestion',
      'Respiration',
      'Circulation',
      'Skeleton & Muscles',
    ]),
    Module('Biology — Reproduction', [
      'Puberty',
      'Reproductive Systems',
      'Fertilisation',
      'Sexual Reproduction',
      'Plant Reproduction',
    ]),
    Module('Chemistry — Atoms & Elements', [
      'Atomic Structure',
      'The Periodic Table',
      'Chemical Formulae',
      'Chemical Properties',
      'Compounds',
    ]),
    Module('Physics — Electricity & Magnetism', [
      'Electric Circuits',
      'Current & Voltage',
      'Resistance',
      'Magnets',
      'Electromagnets',
    ]),
    Module('Physics — Light, Sound & Space', [
      'Light',
      'Reflection',
      'Sound',
      'Solar System',
      'Universe',
    ]),
  ]),
  'year9': Level('Year 9 - Age 13–14', [
    Module('Biology — Genetics & Evolution', [
      'DNA & Genes',
      'Chromosomes',
      'Inheritance',
      'Variation',
      'Natural Selection',
    ]),
    Module('Biology — Health & Disease', [
      'Pathogens',
      'Communicable Diseases',
      'Immune System',
      'Vaccination',
      'Medicines',
    ]),
    Module('Chemistry — Chemical Reactions', [
      'Chemical Equations',
      'Acids & Alkalis',
      'pH & Indicators',
      'Reactivity',
      'Rates of Reaction',
    ]),
    Module('Physics — Motion & Energy', [
      'Distance & Displacement',
      'Speed',
      'Acceleration',
      'Work & Power',
      'Energy Efficiency',
    ]),
    Module('Biology — Ecology & Environment', [
      'Populations',
      'Biodiversity',
      'Food & Energy',
      'Carbon Cycle',
      'Climate Change',
    ]),
  ]),
  'year10': Level('Year 10 - Age 14–15', [
    Module('Biology — Cell Biology', [
      'Cell Division',
      'Transport in Cells',
      'Enzymes',
      'Photosynthesis',
      'Respiration',
    ]),
    Module('Biology — Organisation & Homeostasis', [
      'Digestive System',
      'Nervous System',
      'Hormones',
      'Homeostasis',
      'Maintaining Internal Conditions',
    ]),
    Module('Chemistry — Bonding & Materials', [
      'Ionic Bonding',
      'Covalent Bonding',
      'Metallic Bonding',
      'Properties of Materials',
      'Chemical Structure',
    ]),
    Module('Physics — Forces & Electricity', [
      "Newton's Laws",
      'Momentum',
      'Electrical Resistance',
      'Electrical Power',
      'Electromagnetism',
    ]),
    Module('Physics — Waves & Radiation', [
      'Wave Properties',
      'Sound Waves',
      'Electromagnetic Waves',
      'Radiation',
      'Uses & Risks of Radiation',
    ]),
  ]),
  'year11': Level('Year 11 - Age 15–16', [
    Module('Biology — Genetics, Evolution & Ecology', [
      'Genetic Inheritance',
      'Genetic Variation',
      'Evolution',
      'Ecosystems',
      'Biodiversity & Conservation',
    ]),
    Module('Biology — Health & Homeostasis', [
      'Disease & Immunity',
      'Nervous System',
      'Hormonal Control',
      'Reproduction & Hormones',
      'Homeostasis',
    ]),
    Module('Chemistry — Chemistry in the Real World', [
      'Electrolysis',
      'Chemical Analysis',
      'Organic Chemistry',
      'Fuels & Energy',
      'Sustainable Chemistry',
    ]),
    Module('Physics — Physics in the Real World', [
      'Energy Resources',
      'Electricity in the Home',
      'Forces & Motion',
      'Magnetism & Electromagnetism',
      'Space Physics',
    ]),
    Module('Scientific Skills', [
      'Planning Investigations',
      'Experimental Methods',
      'Analysing Data',
      'Evaluating Evidence',
      'Scientific Communication',
    ]),
  ]),
};
