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
  const _ProfileContent({required this.data});

  final Map<String, dynamic> data;

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
        Text(
          'Experiences',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        const _ExperiencesCard(),
      ],
    );
  }

  static String _initials(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return 'EW';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
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

// Retained for a possible future return of profile-level filters.
// ignore: unused_element
class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ProfileTab(
            label: 'Info',
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          const SizedBox(width: 12),
          _ProfileTab(
            label: 'Connections',
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? ProfileScreen.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? ProfileScreen.green : const Color(0xFFD9D9D9),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            color: selected ? Colors.white : const Color(0xFF171717),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// The Home Connections feed remains active; this profile list is dormant.
// ignore: unused_element
class _ConnectionsContent extends StatelessWidget {
  const _ConnectionsContent({required this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    if (userId == null) return const _EmptyConnections();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('parents')
          .orderBy('addedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ConnectionsMessage(
            title: 'Could not load connections',
            description: 'Please try again in a moment.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: ProfileScreen.green,
              strokeWidth: 2,
            ),
          );
        }
        if (snapshot.data!.docs.isEmpty) return const _EmptyConnections();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: Color(0xFFEAEAEA)),
          itemBuilder: (context, index) {
            return _ConnectionTile(data: snapshot.data!.docs[index].data());
          },
        );
      },
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final storedName = data['name'];
    final name = storedName is String && storedName.trim().isNotEmpty
        ? storedName.trim()
        : 'Connection';

    return SizedBox(
      height: 76,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEDF4FF),
            child: Text(
              _initials(name),
              style: GoogleFonts.lato(
                color: const Color(0xFF317ABE),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            name,
            style: GoogleFonts.lato(
              color: const Color(0xFF171717),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
  }
}

class _EmptyConnections extends StatelessWidget {
  const _EmptyConnections();

  @override
  Widget build(BuildContext context) {
    return const _ConnectionsMessage(
      title: 'Your connections',
      description:
          'See experiences, questions and conversations\nshared by the people you’re connected with.',
    );
  }
}

class _ConnectionsMessage extends StatelessWidget {
  const _ConnectionsMessage({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: const Color(0xFF171717),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: const Color(0xFF444444),
                fontSize: 16,
                height: 1.42,
              ),
            ),
          ],
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
