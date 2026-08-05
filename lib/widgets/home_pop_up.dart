import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeGuidelinesPopup extends StatefulWidget {
  const HomeGuidelinesPopup({super.key});

  @override
  State<HomeGuidelinesPopup> createState() => _HomeGuidelinesPopupState();
}

class _HomeGuidelinesPopupState extends State<HomeGuidelinesPopup> {
  static const _green = Color(0xFF0DA64A);
  static const _pages = [
    _GuidelinePage(
      icon: Icons.diversity_1_outlined,
      title: 'Different journeys. Shared support.',
      description:
          'Every family homeschools differently.\nCelebrate different approaches, cultures,\nteaching styles, and experiences.',
      footer:
          'Be kind, listen first, and help create a space\nwhere every parent feels welcome.',
    ),
    _GuidelinePage(
      icon: Icons.family_restroom_outlined,
      title: 'Parents connect. Children stay\nprotected.',
      description:
          'Classmates is designed for parents and\ncarers. Never share personal details about\nchildren, including names, locations, or\nprivate information.',
    ),
    _GuidelinePage(
      icon: Icons.forum_outlined,
      title: 'Help our community grow',
      description:
          'Ask questions, share your experiences,\nrecommend activities, and celebrate\ndiscoveries.',
      footer:
          'The best communities are built by parents\nwho support each other.',
    ),
    _GuidelinePage(
      icon: Icons.handshake_outlined,
      title: 'A community built on trust',
      description:
          'Classmates brings homeschooling families\ntogether to share experiences, discover\nopportunities, and support each other.',
      footer:
          "Let's keep our community friendly,\nrespectful, and helpful for everyone.",
    ),
  ];

  int _pageIndex = 0;

  void _continue() {
    if (_pageIndex == _pages.length - 1) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _pageIndex++);
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_pageIndex];
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      insetPadding: const EdgeInsets.only(top: 70),
      alignment: Alignment.bottomCenter,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: screenHeight * 0.76,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
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
                'Some Classmates Guidelines',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: const Color(0xFF171717),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Container(
                  key: ValueKey(_pageIndex),
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF4),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(page.icon, size: 74, color: _green),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: const Color(0xFF3F3F46),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: const Color(0xFF52525B),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              if (page.footer case final footer?) ...[
                const SizedBox(height: 16),
                Text(
                  footer,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF52525B),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: index == _pageIndex ? 8 : 7,
                    height: index == _pageIndex ? 8 : 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == _pageIndex
                          ? _green
                          : const Color(0xFFD9D9D9),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
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

class _GuidelinePage {
  const _GuidelinePage({
    required this.icon,
    required this.title,
    required this.description,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? footer;
}
