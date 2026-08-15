import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum _ResourcesView { bySubject, saved }

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key, required this.onTabSelected});

  final ValueChanged<int> onTabSelected;

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  static const _green = Color(0xFF08A948);

  static const _subjects = <(String?, IconData, String)>[
    ('assets/resourcesIocns/pe.png', Icons.circle_outlined, 'P.E'),
    (
      'assets/resourcesIocns/lifeskilss.png',
      Icons.circle_outlined,
      'Life Skills',
    ),
    ('assets/resourcesIocns/languages.png', Icons.circle_outlined, 'Languages'),
    ('assets/resourcesIocns/music.png', Icons.circle_outlined, 'Music'),
    ('assets/resourcesIocns/religiuos.png', Icons.circle_outlined, 'Religious'),
    ('assets/resourcesIocns/computing.png', Icons.circle_outlined, 'Computing'),
    ('assets/resourcesIocns/Art.png', Icons.circle_outlined, 'Art'),
    ('assets/resourcesIocns/geography.png', Icons.circle_outlined, 'Geography'),
    ('assets/resourcesIocns/histoyIcon.png', Icons.circle_outlined, 'History'),
    ('assets/resourcesIocns/science.png', Icons.circle_outlined, 'Science'),
    ('assets/resourcesIocns/maths.png', Icons.circle_outlined, 'Maths'),
    ('assets/resourcesIocns/english.png', Icons.circle_outlined, 'English'),
  ];

  static const _savedResources = <(String, String)>[
    ('1066: The Norman Conquest', 'History · PDF · 4 pages'),
    ('The Victorians: Life in Britain', 'History · PDF · 4 pages'),
    ('Life in Medieval Britain', 'History · PDF · 4 pages'),
    ('The Romans: Britain & Beyond', 'History · PDF · 4 pages'),
  ];

  _ResourcesView _view = _ResourcesView.bySubject;

  @override
  Widget build(BuildContext context) {
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
              const _ResourcesHeader(),
              const Divider(height: 1, color: Color(0xFFEAEAEA)),
              Expanded(
                child: _view == _ResourcesView.bySubject
                    ? _buildSubjectGrid()
                    : _buildSavedList(),
              ),
              _buildViewSelector(),
            ],
          ),
        ),
        bottomNavigationBar: _ResourcesNavigation(onTap: widget.onTabSelected),
      ),
    );
  }

  Widget _buildSubjectGrid() {
    return GridView.builder(
      key: const ValueKey('resource-subjects'),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.88,
      ),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        return Material(
          color: const Color(0xFFF4F9F6),
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (subject.$1 case final iconAsset?)
                  Image.asset(
                    iconAsset,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  )
                else
                  Icon(subject.$2, size: 22, color: const Color(0xFF181818)),
                const SizedBox(height: 12),
                Text(
                  subject.$3,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    color: const Color(0xFF181818),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedList() {
    return ListView.separated(
      key: const ValueKey('saved-resources'),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      itemCount: _savedResources.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final resource = _savedResources[index];
        return Material(
          color: const Color(0xFFF4F9F6),
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.$1,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF181818),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    resource.$2,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF777777),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ResourcesChip(
            label: 'By Subject',
            selected: _view == _ResourcesView.bySubject,
            onTap: () => setState(() => _view = _ResourcesView.bySubject),
          ),
          const SizedBox(width: 12),
          _ResourcesChip(
            label: 'Saved',
            selected: _view == _ResourcesView.saved,
            onTap: () => setState(() => _view = _ResourcesView.saved),
          ),
        ],
      ),
    );
  }
}

class _ResourcesHeader extends StatelessWidget {
  const _ResourcesHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Text(
            'Resources',
            style: GoogleFonts.lato(
              color: const Color(0xFF171717),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourcesChip extends StatelessWidget {
  const _ResourcesChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _ResourcesScreenState._green : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? _ResourcesScreenState._green
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            label,
            style: GoogleFonts.lato(
              color: selected ? Colors.white : const Color(0xFF181818),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourcesNavigation extends StatelessWidget {
  const _ResourcesNavigation({required this.onTap});

  final ValueChanged<int> onTap;

  static const _items = [
    ('assets/HomeIcon.png', 'Home'),
    ('assets/ExperienceIcon.png', 'Experiences'),
    ('assets/Resources_Active.png', 'Resources'),
    ('assets/profileIcon.png', 'Profile'),
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
                      color: index == 2 ? null : const Color(0xFF7A7A7A),
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$2,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: index == 2
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
