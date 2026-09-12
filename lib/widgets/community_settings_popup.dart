import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'message_widget.dart';

Future<void> showCommunitySettingsPopup(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      builder: (_) => const CommunitySettingsPopup(),
    );

class CommunitySettingsPopup extends StatefulWidget {
  const CommunitySettingsPopup({super.key});

  @override
  State<CommunitySettingsPopup> createState() => _CommunitySettingsPopupState();
}

class _CommunitySettingsPopupState extends State<CommunitySettingsPopup> {
  static const green = Color(0xFF00AD4D);
  static const blue = Color(0xFF315DB5);
  int _childCount = 1;
  final List<int> _childAges = [9, 9, 9, 9];
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
      final saved = profile.data()?['childAges'];
      if (!mounted) return;
      setState(() {
        if (saved is Iterable) {
          final ages = saved
              .whereType<num>()
              .map((age) => age.toInt())
              .toList();
          if (ages.isNotEmpty) {
            _childCount = ages.length.clamp(1, 4);
            for (var i = 0; i < _childCount; i++) {
              _childAges[i] = ages[i].clamp(2, 18);
            }
          }
        }
        _isLoading = false;
      });
    } on FirebaseException {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isSaving) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'childCount': _childCount,
        'childAges': _childAges.take(_childCount).toList(),
        'locationSharingEnabled': true,
        'discoveryRadius': 'Anywhere in the UK',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        Navigator.of(context).pop();
        showMessagePopupInOverlay(
          overlay,
          message: 'Community settings updated successfully.',
        );
      }
    } on FirebaseException {
      if (mounted) {
        setState(() => _isSaving = false);
        showMessagePopup(
          context,
          message: 'Could not update community settings.',
          type: MessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.73,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 16, 30, 18),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: green,
                      strokeWidth: 2,
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFDDDDDD),
                                    ),
                                  ),
                                  child: const Icon(Icons.close, size: 19),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Community settings',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Your child’s age and your location help us connect '
                              'you with the right community and show you relevant '
                              'posts and conversations nearby.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                final count = index + 1;
                                final selected = count == _childCount;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index == 3 ? 0 : 10,
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _childCount = count),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 54,
                                      height: 56,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selected ? blue : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: selected
                                              ? blue
                                              : const Color(0xFFD7D7D7),
                                        ),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: GoogleFonts.lato(
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF777777),
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 20),
                            ...List.generate(
                              _childCount,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ChildAgeField(
                                  index: index,
                                  age: _childAges[index],
                                  onChanged: (age) =>
                                      setState(() => _childAges[index] = age),
                                ),
                              ),
                            ),
                            const SizedBox(height: 54),
                            const _SettingSummary(
                              title: 'Current location',
                              value: 'Using your current location',
                            ),
                            const SizedBox(height: 44),
                            const _SettingSummary(
                              title: 'Discovery radius within',
                              value: 'Anywhere in the UK',
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 43,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _updateSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: green.withValues(
                              alpha: 0.6,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Update',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
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
}

class _ChildAgeField extends StatelessWidget {
  const _ChildAgeField({
    required this.index,
    required this.age,
    required this.onChanged,
  });
  final int index;
  final int age;
  final ValueChanged<int> onChanged;

  Future<void> _pickAge(BuildContext context) async {
    var selectedAge = age;
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: 300,
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
                      onPressed: () => Navigator.pop(sheetContext, selectedAge),
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
                    initialItem: age - 2,
                  ),
                  onSelectedItemChanged: (index) => selectedAge = index + 2,
                  children: List.generate(
                    17,
                    (index) => Center(child: Text('${index + 2} years')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _pickAge(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 284,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD7D7D7)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  'Child ${index + 1}',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: const Color(0xFF505050),
                  ),
                ),
                const Spacer(),
                Text(
                  '$age years',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: _CommunitySettingsPopupState.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: _CommunitySettingsPopupState.green,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingSummary extends StatelessWidget {
  const _SettingSummary({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.lato(fontSize: 15)),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.lato(
            color: _CommunitySettingsPopupState.green,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
