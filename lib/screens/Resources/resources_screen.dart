import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/message_widget.dart';
import '../../widgets/screen_info_popup.dart';
import 'subject_resources_screen.dart';

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

  final List<ResourceItem> _savedResources = [];
  final Set<String> _savedResourceIds = {};
  List<ResourceItem> _availableResources = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _savedResourcesSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _resourcesSubscription;

  _ResourcesView _view = _ResourcesView.bySubject;

  @override
  void initState() {
    super.initState();
    _listenForSavedResources();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showScreenInfoOnFirstVisit(context, ScreenInfoType.resources);
      }
    });
  }

  @override
  void dispose() {
    _savedResourcesSubscription?.cancel();
    _resourcesSubscription?.cancel();
    super.dispose();
  }

  void _listenForSavedResources() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _savedResourcesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedResources')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          setState(() {
            _savedResourceIds
              ..clear()
              ..addAll(snapshot.docs.map((document) => document.id));
            _syncSavedResources();
          });
        });

    _resourcesSubscription = FirebaseFirestore.instance
        .collection('resources')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          setState(() {
            _availableResources = snapshot.docs
                .map(ResourceItem.fromDocument)
                .toList();
            _syncSavedResources();
          });
        });
  }

  void _syncSavedResources() {
    _savedResources
      ..clear()
      ..addAll(
        _availableResources.where(
          (resource) => _savedResourceIds.contains(resource.id),
        ),
      );
  }

  Future<void> _saveResource(ResourceItem resource) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('User is not signed in');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedResources')
        .doc(resource.id)
        .set({
          'resourceId': resource.id,
          'savedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _removeSavedResource(ResourceItem resource) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('User is not signed in');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savedResources')
        .doc(resource.id)
        .delete();
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
              _ResourcesHeader(
                onInfoPressed: () =>
                    showScreenInfoPopup(context, ScreenInfoType.resources),
              ),
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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SubjectResourcesScreen(
                  subject: subject.$3,
                  initialSavedResourceIds: {..._savedResourceIds},
                  onSave: _saveResource,
                  onRemove: _removeSavedResource,
                ),
              ),
            ),
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
        return _SavedResourceTile(
          resource: resource,
          onRemove: () {
            _removeSavedResource(resource)
                .then((_) {
                  if (context.mounted) {
                    showMessagePopup(context, message: 'Resource removed');
                  }
                })
                .catchError((Object error) {
                  if (context.mounted) {
                    showMessagePopup(
                      context,
                      message: 'Unable to remove this resource.',
                      type: MessageType.error,
                    );
                  }
                });
          },
          onGet: () => downloadResourcePdf(context, resource),
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

class _SavedResourceTile extends StatefulWidget {
  const _SavedResourceTile({
    required this.resource,
    required this.onRemove,
    required this.onGet,
  });

  final ResourceItem resource;
  final VoidCallback onRemove;
  final VoidCallback onGet;

  @override
  State<_SavedResourceTile> createState() => _SavedResourceTileState();
}

class _SavedResourceTileState extends State<_SavedResourceTile> {
  static const _actionsWidth = 140.0;
  static const _tileHeight = 88.0;
  double _offset = 0;

  void _run(VoidCallback action) {
    setState(() => _offset = 0);
    action();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          SizedBox(
            width: _actionsWidth,
            height: _tileHeight,
            child: Row(
              children: [
                _SavedResourceAction(
                  label: 'Remove',
                  iconAsset: 'assets/removeiconup.png',
                  color: const Color(0xFFE00019),
                  onTap: () => _run(widget.onRemove),
                ),
                const SizedBox(width: 8),
                _SavedResourceAction(
                  label: 'Get',
                  iconAsset: 'assets/downloadIcon.png',
                  color: const Color(0xFF08A948),
                  onTap: () => _run(widget.onGet),
                ),
              ],
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (details) => setState(
              () => _offset = (_offset + details.delta.dx).clamp(
                -_actionsWidth,
                0,
              ),
            ),
            onHorizontalDragEnd: (details) {
              final open =
                  _offset.abs() > _actionsWidth / 3 ||
                  (details.primaryVelocity ?? 0) < -250;
              setState(() => _offset = open ? -_actionsWidth : 0);
            },
            child: Transform.translate(
              offset: Offset(_offset, 0),
              child: Container(
                width: double.infinity,
                height: _tileHeight,
                color: const Color(0xFFF4F9F6),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    ResourcePreviewThumbnail(resource: widget.resource),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.resource.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              color: const Color(0xFF181818),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.resource.details,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              color: const Color(0xFF777777),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedResourceAction extends StatelessWidget {
  const _SavedResourceAction({
    required this.label,
    required this.iconAsset,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(5),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 27,
                height: 27,
                child: Image.asset(iconAsset, fit: BoxFit.contain),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourcesHeader extends StatelessWidget {
  const _ResourcesHeader({required this.onInfoPressed});

  final VoidCallback onInfoPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 18, 14),
        child: Row(
          children: [
            Text(
              'Resources',
              style: GoogleFonts.lato(
                color: const Color(0xFF171717),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            ScreenInfoButton(onPressed: onInfoPressed),
          ],
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
    ('assets/experienceIconUpdated.png', 'Experiences'),
    ('assets/calenderIcon.png', 'Plan'),
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
                      width: index == 2 ? 18 : 20,
                      height: 20,
                      color: index == 2 ? null : const Color(0xFF111111),
                      colorBlendMode: index == 2 ? null : BlendMode.srcIn,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$2,
                      style: GoogleFonts.lato(
                        color: const Color(0xFF111111),
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
