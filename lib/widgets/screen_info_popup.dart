import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ScreenInfoType { community, experiences, resources, profile }

extension on ScreenInfoType {
  String get storageKey => 'screen_info_seen_$name';

  String get title => switch (this) {
    ScreenInfoType.community => 'Community',
    ScreenInfoType.experiences => 'Experiences',
    ScreenInfoType.resources => 'Resources',
    ScreenInfoType.profile => 'Profile',
  };

  String get heading => switch (this) {
    ScreenInfoType.community => 'Your homeschooling\ncommunity is here',
    ScreenInfoType.experiences => 'Learn beyond the home',
    ScreenInfoType.resources =>
      'Helpful resources for your\nhomeschooling journey',
    ScreenInfoType.profile => 'Your Connections &\nExperiences',
  };

  String get description => switch (this) {
    ScreenInfoType.community =>
      'Ask questions, share experiences and get advice\nfrom other parents. Keep conversations\nrespectful and welcoming, and avoid sharing\npersonal information about yourself or your\nchild. Follow our meet-up safety guidance when\nmeeting a connection.',
    ScreenInfoType.experiences =>
      'Explore museums, workshops, nature,\nattractions, heritage, sport and more. Find\nexperiences that connect to your child’s learning,\nturning everyday outings into opportunities to\nexplore, discover and learn.',
    ScreenInfoType.resources =>
      'Explore resources by subject to find ideas,\nguidance and useful materials to support your\nchild’s learning.',
    ScreenInfoType.profile =>
      'Add parents and carers using your connection\ncode and keep track of the experiences you’ve\nvisited.',
  };

  String get asset => switch (this) {
    ScreenInfoType.community => 'assets/screensIcons/communityIcon.png',
    ScreenInfoType.experiences => 'assets/screensIcons/ExprienceIcon.png',
    ScreenInfoType.resources => 'assets/screensIcons/resourcesIcon.png',
    ScreenInfoType.profile => 'assets/screensIcons/profileIcon.png',
  };
}

Future<void> showScreenInfoOnFirstVisit(
  BuildContext context,
  ScreenInfoType type,
) async {
  final preferences = await SharedPreferences.getInstance();
  final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  final storageKey = '${type.storageKey}_$userId';
  if (preferences.getBool(storageKey) == true || !context.mounted) return;

  await showScreenInfoPopup(context, type);
  await preferences.setBool(storageKey, true);
}

Future<void> showScreenInfoPopup(BuildContext context, ScreenInfoType type) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black45,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _ScreenInfoSheet(type: type),
  );
}

class ScreenInfoButton extends StatelessWidget {
  const ScreenInfoButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(side: BorderSide(color: Color(0xFFE5E5E5))),
    child: InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: const SizedBox(
        width: 34,
        height: 34,
        child: Icon(Icons.info_outline_rounded, size: 17),
      ),
    ),
  );
}

class _ScreenInfoSheet extends StatelessWidget {
  const _ScreenInfoSheet({required this.type});

  static const _green = Color(0xFF0DA64A);
  final ScreenInfoType type;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: height * 0.67,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
          child: Column(
            children: [
              Text(
                type.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                flex: 4,
                child: Center(
                  child: type == ScreenInfoType.experiences
                      ? OverflowBox(
                          maxWidth: MediaQuery.sizeOf(context).width,
                          child: SizedBox(
                            width: MediaQuery.sizeOf(context).width,
                            child: Image.asset(
                              type.asset,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        )
                      : SizedBox(
                          width: type == ScreenInfoType.community ? 195 : null,
                          child: Transform.scale(
                            scale: type == ScreenInfoType.resources ? 1.12 : 1,
                            child: Image.asset(type.asset, fit: BoxFit.contain),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                type.heading,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                type.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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
