import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
      widget.subject == 'Mathematics' || widget.subject == 'English';

  Map<String, Level> get _subjectLevels =>
      widget.subject == 'English' ? englishLevels : mathsLevels;

  Level? get _level =>
      _isSupported && _levelId != null ? _subjectLevels[_levelId] : null;

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
      _levelId = data?['startingPointId'] as String?;
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
      final exists = (await document.get()).exists;
      await document.set({
        'subject': widget.subject,
        'childNumber': widget.childNumber,
        'startingPointId': _levelId,
        'topicStatuses': _statuses,
        if (!exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this progress.')),
        );
      }
    }
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
                      ]
                    : [
                        Text(
                          level.label,
                          style: GoogleFonts.lato(
                            color: green,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                      _PathButton(label: 'GCSE Pathway', selected: true),
                      const SizedBox(width: 12),
                      _PathButton(label: 'Flexible Pathway', selected: false),
                    ],
                  ),
                ),
              )
            : null,
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
  const _PathButton({required this.label, required this.selected});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () {},
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
  ('age11', 'Primary — Age 11'),
  ('year7', 'Year 7 — Age 11–12'),
  ('year8', 'Year 8 — Age 12–13'),
  ('year9', 'Year 9 — Age 13–14'),
  ('year10', 'Year 10 — Age 14–15'),
  ('year11', 'Year 11 — Age 15–16'),
];

const mathsLevels = <String, Level>{
  'age5': Level('Age 5', [
    Module('Number', [
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
      'Finding halves and quarters',
      'Recognising thirds',
      'Describing properties of shapes',
      'Measuring in centimetres and metres',
      'Reading simple scales and charts',
    ]),
    Module('Time, Money & Data', [
      'Telling time to the hour',
      'Telling time to half past',
      'Telling time with o’clock',
      'Reading simple change',
      'Finding simple tables and charts',
    ]),
  ]),
  'age7': Level('Age 7', [
    Module('Number & Place Value', [
      'Numbers to 1,000',
      'Hundreds, tens and ones',
      'Ordering numbers',
      'Rounding to nearest 10',
      'Using number lines',
    ]),
    Module('Calculations', [
      'Adding three-digit numbers',
      'Subtracting three-digit numbers',
      'Using inverse operations',
      'Estimating answers',
      'Solving two-step problems',
    ]),
    Module('Multiplication & Division', [
      '3, 4 and 8 times tables',
      'Applying multiplication facts',
      'Written multiplication',
      'Written division',
    ]),
    Module('Fractions & Measure', [
      'Equivalent fractions',
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
    Module('Fractions', [
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
      'Solving problems with scale drawings',
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
      'Directed numbers',
      'Place value',
      'Fractions',
      'Decimals and percentages',
    ]),
    Module('Algebra', [
      'Algebraic notation',
      'Substitution',
      'Expressions',
      'Linear sequences',
    ]),
    Module('Ratio & Proportion', [
      'Ratio notation',
      'Sharing in a ratio',
      'Proportion problems',
    ]),
    Module('Geometry', ['Angles', 'Perimeter and area', 'Transformations']),
    Module('Statistics & Probability', [
      'Averages',
      'Charts and graphs',
      'Basic probability',
    ]),
  ]),
  'year8': Level('Year 8 - Age 12–13', [
    Module('Number', [
      'Fractions and percentages',
      'Standard form',
      'Powers and roots',
    ]),
    Module('Algebra', [
      'Expanding brackets',
      'Factorising',
      'Solving equations',
    ]),
    Module('Ratio & Proportion', [
      'Direct proportion',
      'Rates of change',
      'Scale drawings',
    ]),
    Module('Geometry', ['Constructions', 'Congruence', 'Volume of prisms']),
    Module('Statistics & Probability', [
      'Scatter graphs',
      'Grouped data',
      'Experimental probability',
    ]),
  ]),
  'year9': Level('Year 9 - Age 13–14', [
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
    Module('Equations & Inequalities', [
      'Solving linear equations',
      'Forming equations',
      'Representing inequalities',
    ]),
    Module('Ratio & Proportion', [
      'Ratio problems',
      'Direct and inverse proportion',
      'Compound measures',
    ]),
    Module('Sequences & Graphs', [
      'Arithmetic sequences',
      'Real-life graphs',
      'Quadratic sequences',
    ]),
    Module('Geometry & Measure', [
      'Pythagoras theorem',
      'Transformations',
      'Circles',
    ]),
    Module('Statistics', [
      'Sampling',
      'Cumulative frequency',
      'Interpreting data',
    ]),
    Module('Probability', [
      'Combined events',
      'Tree diagrams',
      'Relative frequency',
    ]),
    Module('Mathematical Reasoning', [
      'Proof',
      'Problem solving',
      'Checking solutions',
    ]),
  ]),
  'year10': Level('Year 10 - Age 14–15', [
    Module('Number', [
      'Surds',
      'Bounds',
      'Standard form',
      'Recurring decimals',
    ]),
    Module('Algebra', [
      'Quadratic equations',
      'Simultaneous equations',
      'Functions',
    ]),
    Module('Geometry', ['Trigonometry', 'Vectors', 'Circle theorems']),
    Module('Ratio & Proportion', ['Growth and decay', 'Compound measures']),
    Module('Statistics & Probability', [
      'Histograms',
      'Cumulative frequency',
      'Conditional probability',
    ]),
  ]),
  'year11': Level('Year 11 - Age 15–16', [
    Module('Number', [
      'Exact values',
      'Bounds and error intervals',
      'Exam-ready number skills',
    ]),
    Module('Algebra', [
      'Advanced quadratics',
      'Algebraic fractions',
      'Graph transformations',
    ]),
    Module('Geometry', [
      'Advanced trigonometry',
      'Vectors and proof',
      'Similarity',
    ]),
    Module('Statistics & Probability', [
      'Distributions',
      'Probability trees',
      'Venn diagrams',
    ]),
    Module('GCSE Problem Solving', [
      'Multi-step problems',
      'Mathematical proof',
      'Exam technique',
    ]),
  ]),
};

const englishLevels = <String, Level>{
  'age5': Level('Age 5', [
    Module('Reading', [
      'Phonics and letter sounds',
      'Blending simple words',
      'Common exception words',
      'Talking about stories',
    ]),
    Module('Writing', [
      'Forming letters',
      'Writing simple words',
      'Writing short sentences',
      'Capital letters and full stops',
    ]),
    Module('Speaking & Listening', [
      'Listening carefully',
      'Taking turns',
      'Retelling familiar stories',
    ]),
  ]),
  'age6': Level('Age 6', [
    Module('Reading', [
      'Secure phonics',
      'Reading aloud fluently',
      'Predicting events',
      'Answering questions about a text',
    ]),
    Module('Writing', [
      'Spelling common words',
      'Joining ideas with and',
      'Sentence punctuation',
      'Checking written work',
    ]),
    Module('Grammar', [
      'Nouns and verbs',
      'Capital letters',
      'Question marks and exclamation marks',
    ]),
  ]),
  'age7': Level('Age 7', [
    Module('Reading', [
      'Reading with expression',
      'Making predictions',
      'Finding information',
      'Discussing new vocabulary',
    ]),
    Module('Writing', [
      'Planning short pieces',
      'Using expanded noun phrases',
      'Past and present tense',
      'Editing and improving',
    ]),
    Module('Spelling & Grammar', [
      'Spelling patterns',
      'Commas in lists',
      'Apostrophes',
      'Sentence types',
    ]),
  ]),
  'age8': Level('Age 8', [
    Module('Reading', [
      'Reading a range of texts',
      'Retrieving information',
      'Making inferences',
      'Summarising main ideas',
    ]),
    Module('Writing', [
      'Organising paragraphs',
      'Writing for different purposes',
      'Direct speech',
      'Proofreading',
    ]),
    Module('Language', [
      'Prefixes and suffixes',
      'Word families',
      'Conjunctions',
      'Present perfect tense',
    ]),
  ]),
  'age9': Level('Age 9', [
    Module('Reading', [
      'Fluent independent reading',
      'Explaining vocabulary',
      'Inference with evidence',
      'Comparing texts',
    ]),
    Module('Writing', [
      'Planning and drafting',
      'Building cohesion',
      'Descriptive language',
      'Editing for accuracy',
    ]),
    Module('Grammar & Punctuation', [
      'Relative clauses',
      'Modal verbs',
      'Parenthesis',
      'Commas for clarity',
    ]),
  ]),
  'age10': Level('Age 10', [
    Module('Reading', [
      'Analysing language choices',
      'Summarising across paragraphs',
      'Identifying themes',
      'Evaluating viewpoints',
    ]),
    Module('Writing', [
      'Writing for audience and purpose',
      'Cohesion across paragraphs',
      'Formal and informal tone',
      'Precise vocabulary',
    ]),
    Module('Grammar & Punctuation', [
      'Active and passive voice',
      'Perfect verb forms',
      'Colons and semicolons',
      'Hyphens',
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
    Module('Reading Literature', [
      'Character and theme',
      'Language and structure',
      'Using quotations',
      'Poetry analysis',
    ]),
    Module('Writing', [
      'Creative writing',
      'Transactional writing',
      'Paragraph cohesion',
      'Technical accuracy',
    ]),
    Module('Language', [
      'Word classes',
      'Sentence structures',
      'Rhetorical devices',
      'Spoken presentations',
    ]),
  ]),
  'year8': Level('Year 8 - Age 12–13', [
    Module('Literature', [
      'Analysing prose',
      'Drama and performance',
      'Poetic form',
      'Context and interpretation',
    ]),
    Module('Non-fiction', [
      'Writers’ viewpoints',
      'Comparing sources',
      'Persuasive techniques',
      'Summarising information',
    ]),
    Module('Writing Craft', [
      'Voice and viewpoint',
      'Structure and pace',
      'Imagery',
      'Editing for effect',
    ]),
  ]),
  'year9': Level('Year 9 - Age 13–14', [
    Module('Shakespeare & Drama', [
      'Character development',
      'Themes',
      'Dramatic methods',
      'Using context',
    ]),
    Module('Prose & Poetry', [
      'Close language analysis',
      'Structure',
      'Comparing poems',
      'Critical response',
    ]),
    Module('English Language', [
      'Creative reading',
      'Creative writing',
      'Viewpoints and perspectives',
      'Transactional writing',
    ]),
  ]),
  'year10': Level('Year 10 - Age 14–15', [
    Module('GCSE Literature', [
      'Shakespeare',
      'Nineteenth-century novel',
      'Modern text',
      'Poetry anthology',
    ]),
    Module('GCSE Language', [
      'Analysing fiction',
      'Descriptive and narrative writing',
      'Analysing non-fiction',
      'Writing viewpoints',
    ]),
    Module('Exam Skills', [
      'Selecting evidence',
      'Developing interpretations',
      'Comparing texts',
      'Timed responses',
    ]),
  ]),
  'year11': Level('Year 11 - Age 15–16', [
    Module('Literature Revision', [
      'Themes and characters',
      'Key quotations',
      'Context',
      'Comparative poetry',
    ]),
    Module('Language Revision', [
      'Reading strategies',
      'Language and structure',
      'Creative writing',
      'Transactional writing',
    ]),
    Module('Exam Preparation', [
      'Planning answers',
      'Timed practice',
      'Technical accuracy',
      'Reviewing responses',
    ]),
  ]),
};
