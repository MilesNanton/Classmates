import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/message_widget.dart';

enum _FilterMode { age, keyStage }

class SubjectResourcesScreen extends StatefulWidget {
  const SubjectResourcesScreen({
    super.key,
    required this.subject,
    required this.onSave,
  });

  final String subject;
  final ValueChanged<(String, String)> onSave;

  @override
  State<SubjectResourcesScreen> createState() => _SubjectResourcesScreenState();
}

class _SubjectResourcesScreenState extends State<SubjectResourcesScreen> {
  static const _green = Color(0xFF08A948);

  static const _historyResources = <_SubjectResource>[
    _SubjectResource(
      'Vikings: Raiders, Traders & Explorers',
      'History · PDF · 4 pages',
      '7-11',
      'KS2',
    ),
    _SubjectResource(
      '1066: The Norman Conquest',
      'History · PDF · 4 pages',
      '7-11',
      'KS2',
    ),
    _SubjectResource(
      'The Victorians: Life in Britain',
      'History · PDF · 4 pages',
      '7-11',
      'KS2',
    ),
    _SubjectResource(
      'The Industrial Revolution',
      'History · PDF · 4 pages',
      '11-14',
      'KS3',
    ),
    _SubjectResource(
      'Life in Medieval Britain',
      'History · PDF · 4 pages',
      '7-11',
      'KS2',
    ),
    _SubjectResource(
      'The Romans: Britain & Beyond',
      'History · PDF · 4 pages',
      '7-11',
      'KS2',
    ),
    _SubjectResource(
      'Anglo-Saxons: Life in Britain',
      'History · PDF · 4 pages',
      '7-11',
      'KS2',
    ),
  ];

  static const _ageFilters = ['3-5', '5-7', '7-11', '11-14', '14-16'];
  static const _stageFilters = ['All', 'Early Years', 'KS1', 'KS2', 'KS3'];

  _FilterMode _mode = _FilterMode.age;
  String _age = '7-11';
  String _keyStage = 'All';

  List<_SubjectResource> get _visibleResources {
    final resources = widget.subject == 'History'
        ? _historyResources
        : const <_SubjectResource>[];
    if (_mode == _FilterMode.age) {
      return resources.where((resource) => resource.age == _age).toList();
    }
    if (_keyStage == 'All') return resources;
    return resources
        .where((resource) => resource.keyStage == _keyStage)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final resources = _visibleResources;
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
              _SubjectHeader(
                title: widget.subject,
                onBack: () => Navigator.maybePop(context),
              ),
              const Divider(height: 1, color: Color(0xFFEAEAEA)),
              _buildFilters(),
              Expanded(
                child: resources.isEmpty
                    ? const _NoSubjectResources()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: resources.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final resource = resources[index];
                          return _SwipeableResourceTile(
                            resource: resource,
                            onSave: () {
                              widget.onSave((resource.title, resource.details));
                              showMessagePopup(
                                context,
                                message: 'Resource saved',
                              );
                            },
                            onDownload: () => showMessagePopup(
                              context,
                              message: 'Download coming soon',
                            ),
                          );
                        },
                      ),
              ),
              _buildModeSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = _mode == _FilterMode.age ? _ageFilters : _stageFilters;
    final selected = _mode == _FilterMode.age ? _age : _keyStage;
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return _TopFilterChip(
            label: filter,
            selected: filter == selected,
            onTap: () => setState(() {
              if (_mode == _FilterMode.age) {
                _age = filter;
              } else {
                _keyStage = filter;
              }
            }),
          );
        },
      ),
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SmallFilterChip(
            label: 'Age',
            selected: _mode == _FilterMode.age,
            onTap: () => setState(() => _mode = _FilterMode.age),
          ),
          const SizedBox(width: 12),
          _SmallFilterChip(
            label: 'Key Stage',
            selected: _mode == _FilterMode.keyStage,
            onTap: () => setState(() => _mode = _FilterMode.keyStage),
          ),
        ],
      ),
    );
  }
}

class _TopFilterChip extends StatelessWidget {
  const _TopFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      backgroundColor: selected ? Colors.white : const Color(0xFFF4F9F6),
      side: BorderSide(
        color: selected
            ? _SubjectResourcesScreenState._green
            : Colors.transparent,
        width: 1.5,
      ),
      shape: const StadiumBorder(),
      labelStyle: GoogleFonts.lato(
        color: selected
            ? _SubjectResourcesScreenState._green
            : const Color(0xFF087936),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SubjectResource {
  const _SubjectResource(this.title, this.details, this.age, this.keyStage);

  final String title;
  final String details;
  final String age;
  final String keyStage;
}

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left, size: 22),
                    const SizedBox(width: 2),
                    Text('Back', style: GoogleFonts.lato(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.lato(
              color: const Color(0xFF181818),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeableResourceTile extends StatefulWidget {
  const _SwipeableResourceTile({
    required this.resource,
    required this.onSave,
    required this.onDownload,
  });

  final _SubjectResource resource;
  final VoidCallback onSave;
  final VoidCallback onDownload;

  @override
  State<_SwipeableResourceTile> createState() => _SwipeableResourceTileState();
}

class _SwipeableResourceTileState extends State<_SwipeableResourceTile> {
  static const _actionsWidth = 112.0;
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
            height: 62,
            child: Row(
              children: [
                _ResourceAction(
                  label: 'Save',
                  icon: Icons.favorite_border,
                  color: const Color(0xFFF39A28),
                  onTap: () => _run(widget.onSave),
                ),
                _ResourceAction(
                  label: 'DL',
                  icon: Icons.download_outlined,
                  color: const Color(0xFF08A948),
                  onTap: () => _run(widget.onDownload),
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
                height: 62,
                color: const Color(0xFFF4F9F6),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.resource.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.resource.details,
                      style: GoogleFonts.lato(
                        color: const Color(0xFF777777),
                        fontSize: 12,
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

class _ResourceAction extends StatelessWidget {
  const _ResourceAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 10,
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

class _SmallFilterChip extends StatelessWidget {
  const _SmallFilterChip({
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
      color: selected ? _SubjectResourcesScreenState._green : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? _SubjectResourcesScreenState._green
              : const Color(0xFFE1E7E3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.lato(
              color: selected ? Colors.white : const Color(0xFF08A948),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoSubjectResources extends StatelessWidget {
  const _NoSubjectResources();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No resources yet',
              style: GoogleFonts.lato(
                color: const Color(0xFF181818),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'We’re adding resources to this subject. Check back soon for helpful activities, guides and learning materials.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: const Color(0xFF333333),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
