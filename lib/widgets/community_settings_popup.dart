import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showCommunitySettingsPopup(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => const CommunitySettingsPopup(),
  );
}

class CommunitySettingsPopup extends StatefulWidget {
  const CommunitySettingsPopup({super.key});

  @override
  State<CommunitySettingsPopup> createState() => _CommunitySettingsPopupState();
}

class _CommunitySettingsPopupState extends State<CommunitySettingsPopup> {
  static const _green = Color(0xFF0DA64A);
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

  int _tabIndex = 0;
  String? _selectedApproach;
  final Set<String> _selectedSubjects = {};
  bool _locationSharingEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = profile.data();
      if (!mounted) return;
      setState(() {
        _selectedApproach = data?['homeschoolApproach'] as String?;
        _selectedSubjects
          ..clear()
          ..addAll(
            data?['subjects'] is Iterable
                ? (data!['subjects'] as Iterable).whereType<String>()
                : const <String>[],
          );
        _locationSharingEnabled = data?['locationSharingEnabled'] == true;
        _isLoading = false;
      });
    } on FirebaseException {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save(Map<String, Object> values) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        ...values,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update community settings.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Community settings',
                  style: GoogleFonts.lato(
                    color: const Color(0xFF171717),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Your community is built around these preferences. Update '
                  'them anytime to keep your feed and experiences relevant.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    color: const Color(0xFF737373),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _green,
                            strokeWidth: 2,
                          ),
                        )
                      : _buildSelectedTab(),
                ),
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(color: _green, minHeight: 2),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SettingsTab(
                      label: 'Homeschool style',
                      selected: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                    const SizedBox(width: 10),
                    _SettingsTab(
                      label: 'Subjects',
                      selected: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                    const SizedBox(width: 10),
                    _SettingsTab(
                      label: 'Location',
                      selected: _tabIndex == 2,
                      onTap: () => setState(() => _tabIndex = 2),
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

  Widget _buildSelectedTab() {
    if (_tabIndex == 1) {
      return ListView.separated(
        itemCount: _subjects.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          final selected = _selectedSubjects.contains(subject);
          return _SettingsOption(
            label: subject,
            selected: selected,
            onTap: () {
              setState(() {
                selected
                    ? _selectedSubjects.remove(subject)
                    : _selectedSubjects.add(subject);
              });
              _save({'subjects': _selectedSubjects.toList()});
            },
          );
        },
      );
    }

    if (_tabIndex == 2) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              setState(() => _locationSharingEnabled = true);
              _save({'locationSharingEnabled': true});
            },
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                color: Color(0xFFDCE8FF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 29,
                height: 29,
                decoration: const BoxDecoration(
                  color: Color(0xFF4285F4),
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 38),
          Text(
            'Current location',
            style: GoogleFonts.lato(
              color: const Color(0xFF171717),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              final enabled = !_locationSharingEnabled;
              setState(() => _locationSharingEnabled = enabled);
              _save({'locationSharingEnabled': enabled});
            },
            child: Text(
              _locationSharingEnabled
                  ? 'Using your current location'
                  : 'Location sharing is off',
              style: GoogleFonts.lato(
                color: _locationSharingEnabled
                    ? _green
                    : const Color(0xFF737373),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 44),
          Text(
            'Discovery radius within',
            style: GoogleFonts.lato(
              color: const Color(0xFF171717),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Anywhere in the UK',
            style: GoogleFonts.lato(
              color: _green,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: _approaches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final approach = _approaches[index];
        return _SettingsOption(
          label: approach,
          selected: approach == _selectedApproach,
          onTap: () {
            setState(() => _selectedApproach = approach);
            _save({'homeschoolApproach': approach});
          },
        );
      },
    );
  }
}

class _SettingsOption extends StatelessWidget {
  const _SettingsOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 47,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: selected ? const Color(0xFF3159AA) : Colors.white,
          foregroundColor: selected ? Colors.white : const Color(0xFF737373),
          side: BorderSide(
            color: selected ? const Color(0xFF3159AA) : const Color(0xFFD4D4D4),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0DA64A) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFF0DA64A) : const Color(0xFFD9D9D9),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            color: selected ? Colors.white : const Color(0xFF171717),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
