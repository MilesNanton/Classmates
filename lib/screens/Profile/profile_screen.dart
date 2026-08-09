import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'add_parents_screen.dart';
import 'setting_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onTabSelected});

  static const green = Color(0xFF0DA64A);
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const _ProfileHeader(),
              const Divider(height: 1, color: Color(0xFFEAEAEA)),
              Expanded(
                child: user == null
                    ? const _ProfileContent(data: <String, dynamic>{})
                    : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (context, snapshot) => _ProfileContent(
                          data:
                              snapshot.data?.data() ??
                              <String, dynamic>{
                                'name': user.displayName,
                                'email': user.email,
                              },
                          userId: user.uid,
                        ),
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _ProfileNavigation(onTap: onTabSelected),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 18, 14),
        child: Row(
          children: [
            Text(
              'Profile',
              style: GoogleFonts.lato(
                color: const Color(0xFF171717),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Material(
              color: Colors.white,
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFFE5E5E5)),
              ),
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddParentsScreen(),
                  ),
                ),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.person_add_outlined, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: Colors.white,
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFFE5E5E5)),
              ),
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingScreen(),
                  ),
                ),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.settings_outlined, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.data, this.userId});

  final Map<String, dynamic> data;
  final String? userId;

  String get name {
    final value = data['name'];
    return value is String && value.trim().isNotEmpty
        ? value.trim()
        : 'Emma Williams';
  }

  String get curriculum {
    final value = data['curriculum'];
    return value is String && value.trim().isNotEmpty
        ? value.trim()
        : 'Custom curriculum';
  }

  String get bio => data['bio'] is String ? data['bio'] as String : '';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFEDF4FF),
              child: Text(
                _initials(name),
                style: GoogleFonts.lato(
                  color: const Color(0xFF317ABE),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  curriculum,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: const Color(0xFF5B5B5B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 42),
        Row(
          children: [
            Text(
              'Bio',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (bio.trim().isNotEmpty) ...[
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _openBioEditor(context),
                child: Text(
                  'Edit bio',
                  style: GoogleFonts.lato(
                    color: ProfileScreen.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (bio.trim().isEmpty)
          _EmptyBioCard(onAdd: () => _openBioEditor(context))
        else
          Text(
            bio,
            style: GoogleFonts.lato(
              color: const Color(0xFF444444),
              fontSize: 16,
              height: 1.42,
            ),
          ),
        const SizedBox(height: 72),
        Text(
          'Experiences',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        const _ExperiencesCard(),
      ],
    );
  }

  Future<void> _openBioEditor(BuildContext context) async {
    final savedBio = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      builder: (_) => _BioEditor(initialValue: bio),
    );
    if (savedBio == null || userId == null || !context.mounted) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'bio': savedBio.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your bio. Try again.')),
      );
    }
  }

  static String _initials(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return 'EW';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

class _EmptyBioCard extends StatelessWidget {
  const _EmptyBioCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 17),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            'Add a short bio so other parents in the community can get to know you, your homeschooling approach, and what you’re interested in.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onAdd,
            child: const Text(
              'Add a bio',
              style: TextStyle(
                fontSize: 17,
                color: ProfileScreen.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperiencesCard extends StatelessWidget {
  const _ExperiencesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            'Once you join an experience, it’ll appear here\non your profile.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 14, height: 1.5),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text(
              'What are experiences?',
              style: TextStyle(
                fontSize: 17,
                color: ProfileScreen.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BioEditor extends StatefulWidget {
  const _BioEditor({required this.initialValue});

  final String initialValue;

  @override
  State<_BioEditor> createState() => _BioEditorState();
}

class _BioEditorState extends State<_BioEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue)
      ..addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _controller.text.trim().isNotEmpty;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell parents a little about you',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add a short bio so other parents in the community can get to '
                'know you, your homeschooling approach, and what you’re '
                'interested in.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  color: const Color(0xFF737373),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Add a short bio...',
                    hintStyle: GoogleFonts.lato(
                      color: const Color(0xFF777777),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F7),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: canSave
                      ? () => Navigator.pop(context, _controller.text)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: ProfileScreen.green,
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Save Bio',
                    style: GoogleFonts.lato(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileNavigation extends StatelessWidget {
  const _ProfileNavigation({required this.onTap});

  final ValueChanged<int> onTap;

  static const _items = [
    ('assets/HomeIcon.png', 'Home'),
    ('assets/ExperienceIcon.png', 'Experiences'),
    ('assets/resorcessIcon.png', 'Resources'),
    ('assets/Profile_Active.png', 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 58,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Image.asset(
                      item.$1,
                      width: 20,
                      height: 20,
                      color: index == 3 ? null : const Color(0xFF7A7A7A),
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$2,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: index == 3
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
