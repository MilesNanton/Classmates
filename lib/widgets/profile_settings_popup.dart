import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'message_widget.dart';

Future<void> showProfileSettingsPopup(
  BuildContext context, {
  required String userId,
  required Map<String, dynamic> data,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black45,
  builder: (_) => _ProfileSettingsPopup(userId: userId, data: data),
);

class _ProfileSettingsPopup extends StatefulWidget {
  const _ProfileSettingsPopup({required this.userId, required this.data});
  final String userId;
  final Map<String, dynamic> data;

  @override
  State<_ProfileSettingsPopup> createState() => _ProfileSettingsPopupState();
}

class _ProfileSettingsPopupState extends State<_ProfileSettingsPopup> {
  static const green = Color(0xFF00AD4D);
  static const blue = Color(0xFF3159AA);
  static const approaches = [
    'Traditional',
    'Charlotte Mason',
    'Montessori',
    'Classical Education',
    'Unschooling',
    'Unit Studies',
    'Other',
  ];
  static const avatarColors = [
    Color(0xFFEDF4FF),
    Color(0xFFE9FBF2),
    Color(0xFFF8EAFB),
    Color(0xFFFFF3E9),
  ];
  static const avatarBorderColors = [
    Color(0xFF317ABE),
    Color(0xFF00AD35),
    Color(0xFF8025C7),
    Color(0xFFEB6D00),
  ];

  late int _avatarColorIndex;
  late String _approach;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _avatarColorIndex = (widget.data['avatarColorIndex'] as num?)?.toInt() ?? 0;
    _avatarColorIndex = _avatarColorIndex.clamp(0, avatarColors.length - 1);
    final savedApproach = widget.data['homeschoolApproach'];
    _approach = savedApproach is String && approaches.contains(savedApproach)
        ? savedApproach
        : approaches.first;
  }

  Future<void> _update() async {
    if (_saving) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
            'avatarColorIndex': _avatarColorIndex,
            'homeschoolApproach': _approach,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (mounted) {
        Navigator.of(context).pop();
        showMessagePopupInOverlay(
          overlay,
          message: 'Profile settings updated successfully.',
        );
      }
    } on FirebaseException {
      if (mounted) {
        setState(() => _saving = false);
        showMessagePopup(
          context,
          message: 'Could not update profile settings.',
          type: MessageType.error,
        );
      }
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
          height: MediaQuery.sizeOf(context).height * 0.82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 18),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: Center(
                        child: Text(
                          'Edit profile',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFDDDDDD)),
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(avatarColors.length, (index) {
                    final selected = index == _avatarColorIndex;
                    return Padding(
                      padding: EdgeInsets.only(right: index == 3 ? 0 : 34),
                      child: InkWell(
                        onTap: () => setState(() => _avatarColorIndex = index),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: avatarColors[index],
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(
                                    color: avatarBorderColors[index],
                                    width: 3,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your avatar colour',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: approaches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final label = approaches[index];
                      final selected = label == _approach;
                      return _Option(
                        label: label,
                        selected: selected,
                        onTap: () => setState(() => _approach = label),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _update,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Update',
                            style: GoogleFonts.lato(
                              fontSize: 17,
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

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: selected
            ? _ProfileSettingsPopupState.blue
            : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xFF737373),
        side: BorderSide(
          color: selected
              ? _ProfileSettingsPopupState.blue
              : const Color(0xFFD7D7D7),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      child: Text(label, style: GoogleFonts.lato(fontSize: 17)),
    ),
  );
}
