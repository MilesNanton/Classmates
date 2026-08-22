import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/screen_info_popup.dart';
import 'experience_details_screen.dart';
import 'experience_image_widgets.dart';
import 'experience_metadata.dart';

enum _ExperienceView { all, saved }

class ExperiencesScreen extends StatefulWidget {
  const ExperiencesScreen({super.key, required this.onTabSelected});

  final ValueChanged<int> onTabSelected;

  @override
  State<ExperiencesScreen> createState() => _ExperiencesScreenState();
}

class _ExperiencesScreenState extends State<ExperiencesScreen> {
  static const _green = Color(0xFF08A948);
  static const _categories = [
    'All',
    'Museums & galleries',
    'Workshops & making',
    'Nature & outdoors',
    'Places & attractions',
    'History & heritage',
    'Active & sport',
    'Other',
  ];

  final Set<String> _savedIds = {};
  String _category = 'All';
  _ExperienceView _view = _ExperienceView.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showScreenInfoOnFirstVisit(context, ScreenInfoType.experiences);
      }
    });
  }

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
              _buildHeader(),
              const Divider(height: 1, color: Color(0xFFEAEAEA)),
              _buildCategories(),
              Expanded(child: _buildExperiences()),
              _buildViewSelector(),
            ],
          ),
        ),
        bottomNavigationBar: _ExperiencesNavigation(
          onTap: widget.onTabSelected,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 96,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 18, 14),
        child: Row(
          children: [
            Text(
              'Experiences',
              style: GoogleFonts.lato(
                color: const Color(0xFF171717),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            ScreenInfoButton(
              onPressed: () =>
                  showScreenInfoPopup(context, ScreenInfoType.experiences),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: const RotatedBox(
                quarterTurns: 1,
                child: Icon(Icons.tune_rounded, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _category;
          return ActionChip(
            onPressed: () => setState(() => _category = category),
            label: Text(category),
            backgroundColor: selected ? Colors.white : const Color(0xFFF4F9F6),
            side: BorderSide(
              color: selected ? _green : Colors.transparent,
              width: 1.5,
            ),
            shape: const StadiumBorder(),
            labelStyle: GoogleFonts.lato(
              color: selected ? _green : const Color(0xFF087936),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildExperiences() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('experiences')
          .where('status', isEqualTo: 'published')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ExperienceMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Experiences unavailable',
            subtitle: 'Please check your connection and try again.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _green, strokeWidth: 2),
          );
        }

        final experiences =
            snapshot.data!.docs.where((document) {
                final data = document.data();
                if ((data['status']?.toString().toLowerCase() ?? '') !=
                    'published') {
                  return false;
                }
                if (_view == _ExperienceView.saved &&
                    !_savedIds.contains(document.id)) {
                  return false;
                }
                if (_category == 'All') return true;
                return _matchesCategory(data, _category);
              }).toList()
              ..sort((a, b) => _dateOf(b.data()).compareTo(_dateOf(a.data())));

        if (experiences.isEmpty) {
          return _ExperienceMessage(
            icon: _view == _ExperienceView.saved
                ? Icons.bookmark_border_rounded
                : Icons.explore_outlined,
            title: _view == _ExperienceView.saved
                ? 'No saved experiences'
                : 'No experiences found',
            subtitle: _view == _ExperienceView.saved
                ? 'Open an experience and tap the heart to save it.'
                : 'New experiences will appear here once published.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          itemCount: experiences.length,
          separatorBuilder: (_, _) => const SizedBox(height: 18),
          itemBuilder: (context, index) {
            final experience = experiences[index];
            return _ExperienceCard(
              data: experience.data(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ExperienceDetailsScreen(
                    experience: experience.data(),
                    initiallySaved: _savedIds.contains(experience.id),
                    onSavedChanged: (saved) => setState(() {
                      if (saved) {
                        _savedIds.add(experience.id);
                      } else {
                        _savedIds.remove(experience.id);
                      }
                    }),
                  ),
                ),
              ),
            );
          },
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
          _ViewChip(
            label: 'All',
            selected: _view == _ExperienceView.all,
            onTap: () => setState(() => _view = _ExperienceView.all),
          ),
          const SizedBox(width: 12),
          _ViewChip(
            label: 'Saved',
            selected: _view == _ExperienceView.saved,
            onTap: () => setState(() => _view = _ExperienceView.saved),
          ),
        ],
      ),
    );
  }

  static DateTime _dateOf(Map<String, dynamic> data) {
    final value = data['createdAt'];
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  static bool _matchesCategory(
    Map<String, dynamic> data,
    String selectedCategory,
  ) {
    String normalize(String value) {
      final normalized = value.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
      return normalized.endsWith('s') && normalized != 'arts'
          ? normalized.substring(0, normalized.length - 1)
          : normalized;
    }

    Iterable<String> valuesFor(Object? value) {
      if (value is Iterable) {
        return value.map((item) => item.toString());
      }
      return value == null ? const [] : [value.toString()];
    }

    final selected = normalize(selectedCategory);
    return <String>[
      ...valuesFor(data['subject']),
      ...valuesFor(data['category']),
      ...valuesFor(data['experienceType']),
    ].any((value) => normalize(value) == selected);
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbnail = data['thumbnailUrl']?.toString().trim() ?? '';
    final name = data['name']?.toString().trim();
    final host = data['hostedBy']?.toString().trim();
    final schedule = data['schedule']?.toString().trim();

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                width: double.infinity,
                height: 174,
                child: thumbnail.isEmpty
                    ? const ExperienceImageFallback()
                    : Image.network(
                        thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const ExperienceImageFallback(),
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : const ExperienceImageSkeleton(),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name?.isNotEmpty == true ? name! : 'Experience',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                color: const Color(0xFF171717),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            if (host?.isNotEmpty == true) ...[
              const SizedBox(height: 3),
              Text(
                experienceLocationLabel(host),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
            const SizedBox(height: 3),
            const SizedBox(height: 3),
            Text(
              schedule?.isNotEmpty == true
                  ? schedule!
                  : 'Schedule to be confirmed',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 11,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceMessage extends StatelessWidget {
  const _ExperienceMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: const Color(0xFF8A8A8A)),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 13,
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ViewChip extends StatelessWidget {
  const _ViewChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? _ExperiencesScreenState._green : Colors.white,
    shape: StadiumBorder(
      side: BorderSide(
        color: selected
            ? _ExperiencesScreenState._green
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

class _ExperiencesNavigation extends StatelessWidget {
  const _ExperiencesNavigation({required this.onTap});

  final ValueChanged<int> onTap;
  static const _items = [
    ('assets/HomeIcon.png', 'Community'),
    ('assets/Experiences_Active.png', 'Experiences'),
    ('assets/resorcessIcon.png', 'Resources'),
    ('assets/profileIcon.png', 'Profile'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
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
                    color: index == 1 ? null : const Color(0xFF7A7A7A),
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.$2,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: index == 1
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
