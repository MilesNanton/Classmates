import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubjectProgressScreen extends StatefulWidget {
  const SubjectProgressScreen({super.key, required this.subject, this.entryId});

  final String subject;
  final String? entryId;

  @override
  State<SubjectProgressScreen> createState() => _SubjectProgressScreenState();
}

class _SubjectProgressScreenState extends State<SubjectProgressScreen> {
  static const _green = Color(0xFF00AD4D);
  static const _stages = ['Early Years', 'KS1', 'KS2', 'KS3', 'KS4'];

  static const _goals = <String, List<String>>{
    'English': [
      'Read fluently and explain the meaning of a text',
      'Plan and write clearly for different audiences',
      'Use accurate spelling, punctuation and grammar',
    ],
    'Mathematics': [
      'Build confidence with number and place value',
      'Use the four operations to solve problems',
      'Recognise and work with fractions and measures',
      'Explain mathematical thinking and check answers',
    ],
    'Science': [
      'Ask questions and plan simple investigations',
      'Observe, measure and record results',
      'Use evidence to explain what happened',
    ],
    'History': [
      'Place people and events in chronological order',
      'Compare life in different periods',
      'Use sources to support an historical explanation',
    ],
    'Geography': [
      'Locate places and describe their features',
      'Use maps, atlases and fieldwork observations',
      'Explain how people and environments affect each other',
    ],
    'Music': [
      'Listen closely and describe musical choices',
      'Perform with growing control and confidence',
      'Create and refine a short piece of music',
    ],
    'Art & Design': [
      'Explore materials and practise creative techniques',
      'Develop ideas through sketches and observations',
      'Create and evaluate a finished piece',
    ],
  };

  String? _stage;
  bool _loading = true;

  String get _preferenceKey =>
      'subject_start_${widget.entryId ?? widget.subject.toLowerCase()}';

  @override
  void initState() {
    super.initState();
    _loadStage();
  }

  Future<void> _loadStage() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _stage = preferences.getString(_preferenceKey);
      _loading = false;
    });
  }

  Future<void> _selectStartingPoint() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a starting point',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the level that feels closest to where your child is now.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  color: const Color(0xFF777777),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              ..._stages.map(
                (stage) => ListTile(
                  title: Text(stage, style: GoogleFonts.lato()),
                  trailing: stage == _stage
                      ? const Icon(Icons.check, color: _green)
                      : null,
                  onTap: () => Navigator.pop(context, stage),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, selected);
    if (mounted) setState(() => _stage = selected);
  }

  @override
  Widget build(BuildContext context) {
    final goals = _goals[widget.subject] ?? const <String>[];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leadingWidth: 82,
          leading: TextButton.icon(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left, size: 21),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF333333),
              padding: const EdgeInsets.only(left: 8),
            ),
          ),
          title: Text(
            widget.subject,
            style: GoogleFonts.lato(
              color: const Color(0xFF181818),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFEAEAEA)),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _green))
            : _stage == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    'Choose a starting point to see what your child can work towards in ${widget.subject}.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF777777),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                children: [
                  Text(
                    'Working from $_stage',
                    style: GoogleFonts.lato(
                      color: _green,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What your child can work towards',
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...goals.map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F9F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                              color: _green,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                goal,
                                style: GoogleFonts.lato(
                                  fontSize: 15,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Center(
              heightFactor: 1,
              child: OutlinedButton(
                onPressed: _selectStartingPoint,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF171717),
                  side: const BorderSide(color: _green),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  _stage == null
                      ? 'Select starting point'
                      : 'Change starting point',
                  style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
