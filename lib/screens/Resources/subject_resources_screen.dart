import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internet_file/internet_file.dart';
import 'package:pdfx/pdfx.dart';

import '../../widgets/message_widget.dart';

enum _SubjectResourcesView { bySubject, saved }

class SubjectResourcesScreen extends StatefulWidget {
  const SubjectResourcesScreen({
    super.key,
    required this.subject,
    required this.initialSavedResourceIds,
    required this.onSave,
    required this.onRemove,
  });

  final String subject;
  final Set<String> initialSavedResourceIds;
  final Future<void> Function(ResourceItem) onSave;
  final Future<void> Function(ResourceItem) onRemove;

  @override
  State<SubjectResourcesScreen> createState() => _SubjectResourcesScreenState();
}

class _SubjectResourcesScreenState extends State<SubjectResourcesScreen> {
  static const _green = Color(0xFF08A948);

  static const _ageFilters = ['5-7', '7-11', '11-14', '14-16', 'All ages'];
  late final Set<String> _savedResourceIds;
  _SubjectResourcesView _view = _SubjectResourcesView.bySubject;
  String _age = '5-7';

  @override
  void initState() {
    super.initState();
    _savedResourceIds = {...widget.initialSavedResourceIds};
  }

  List<ResourceItem> _visibleResources(List<ResourceItem> resources) {
    final selectedAge = _normaliseValue(_age);
    return resources
        .where(
          (resource) =>
              _normaliseValue(resource.age) == selectedAge &&
              (_view == _SubjectResourcesView.bySubject ||
                  _savedResourceIds.contains(resource.id)),
        )
        .toList();
  }

  String _normaliseValue(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[–—−]'), '-')
      .replaceAll(RegExp(r'\s+'), '');

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
              _SubjectHeader(
                title: widget.subject,
                onBack: () => Navigator.maybePop(context),
              ),
              const Divider(height: 1, color: Color(0xFFEAEAEA)),
              _buildFilters(),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('resources')
                      .where('status', isEqualTo: 'published')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint('Unable to load resources: ${snapshot.error}');
                      return const _ResourceLoadError();
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: _green),
                      );
                    }
                    final uploadedResources = snapshot.data!.docs
                        .where(
                          (document) =>
                              _normaliseValue(
                                document.data()['subject']?.toString() ?? '',
                              ).replaceAll('.', '') ==
                              _normaliseValue(
                                widget.subject,
                              ).replaceAll('.', ''),
                        )
                        .map(ResourceItem.fromDocument)
                        .toList();
                    final resources = _visibleResources(uploadedResources);
                    if (resources.isEmpty) {
                      return _NoSubjectResources(
                        savedView: _view == _SubjectResourcesView.saved,
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: resources.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final resource = resources[index];
                        return _SwipeableResourceTile(
                          resource: resource,
                          savedView: _view == _SubjectResourcesView.saved,
                          onSave: () {
                            setState(() => _savedResourceIds.add(resource.id));
                            widget
                                .onSave(resource)
                                .then((_) {
                                  if (context.mounted) {
                                    showMessagePopup(
                                      context,
                                      message: 'Resource saved',
                                    );
                                  }
                                })
                                .catchError((Object error) {
                                  if (!context.mounted) return;
                                  setState(
                                    () => _savedResourceIds.remove(resource.id),
                                  );
                                  showMessagePopup(
                                    context,
                                    message: 'Unable to save this resource.',
                                    type: MessageType.error,
                                  );
                                });
                          },
                          onRemove: () {
                            setState(
                              () => _savedResourceIds.remove(resource.id),
                            );
                            widget
                                .onRemove(resource)
                                .then((_) {
                                  if (context.mounted) {
                                    showMessagePopup(
                                      context,
                                      message: 'Resource removed',
                                    );
                                  }
                                })
                                .catchError((Object error) {
                                  if (!context.mounted) return;
                                  setState(
                                    () => _savedResourceIds.add(resource.id),
                                  );
                                  showMessagePopup(
                                    context,
                                    message: 'Unable to remove this resource.',
                                    type: MessageType.error,
                                  );
                                });
                          },
                          onDownload: () =>
                              downloadResourcePdf(context, resource),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildViewSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        scrollDirection: Axis.horizontal,
        itemCount: _ageFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = _ageFilters[index];
          return _TopFilterChip(
            label: filter,
            selected: filter == _age,
            onTap: () => setState(() => _age = filter),
          );
        },
      ),
    );
  }

  Widget _buildViewSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SubjectViewChip(
            label: 'By Subject',
            selected: _view == _SubjectResourcesView.bySubject,
            onTap: () =>
                setState(() => _view = _SubjectResourcesView.bySubject),
          ),
          const SizedBox(width: 12),
          _SubjectViewChip(
            label: 'Saved',
            selected: _view == _SubjectResourcesView.saved,
            onTap: () => setState(() => _view = _SubjectResourcesView.saved),
          ),
        ],
      ),
    );
  }
}

class _SubjectViewChip extends StatelessWidget {
  const _SubjectViewChip({
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
      color: selected ? const Color(0xFF08A948) : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? const Color(0xFF08A948) : const Color(0xFFE0E0E0),
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

class ResourceItem {
  const ResourceItem({
    required this.id,
    required this.title,
    required this.details,
    required this.age,
    required this.pdfUrl,
    required this.thumbnailUrl,
  });

  factory ResourceItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final subject = data['subject']?.toString() ?? 'Resource';
    final pages = (data['pages'] as num?)?.toInt();
    return ResourceItem(
      id: document.id,
      title:
          data['title']?.toString() ?? data['name']?.toString() ?? 'Resource',
      details: '$subject · PDF${pages == null ? '' : ' · $pages pages'}',
      age:
          data['ageRange']?.toString() ?? data['age']?.toString() ?? 'All ages',
      pdfUrl: data['pdfUrl']?.toString() ?? '',
      thumbnailUrl: data['thumbnailUrl']?.toString() ?? '',
    );
  }

  final String id;
  final String title;
  final String details;
  final String age;
  final String pdfUrl;
  final String thumbnailUrl;

  String get detailsWithoutSubject {
    final separator = details.indexOf(' · ');
    return separator == -1 ? details : details.substring(separator + 3);
  }

  @override
  bool operator ==(Object other) => other is ResourceItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

Future<void> downloadResourcePdf(
  BuildContext context,
  ResourceItem resource,
) async {
  if (resource.pdfUrl.isEmpty) {
    showMessagePopup(
      context,
      message: 'This resource does not have a PDF file.',
      type: MessageType.error,
    );
    return;
  }

  try {
    final bytes = await InternetFile.get(resource.pdfUrl);
    final safeName = resource.title
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    await FlutterFileSaver().writeFileAsBytes(
      fileName: '${safeName.isEmpty ? 'resource' : safeName}.pdf',
      bytes: bytes,
    );
    if (!context.mounted) return;
    showMessagePopup(context, message: 'PDF downloaded successfully');
  } on FileSaverCancelledException {
    return;
  } catch (error) {
    debugPrint('Unable to download resource: $error');
    if (!context.mounted) return;
    showMessagePopup(
      context,
      message: 'Unable to download this PDF.',
      type: MessageType.error,
    );
  }
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
    required this.savedView,
    required this.onSave,
    required this.onRemove,
    required this.onDownload,
  });

  final ResourceItem resource;
  final bool savedView;
  final VoidCallback onSave;
  final VoidCallback onRemove;
  final VoidCallback onDownload;

  @override
  State<_SwipeableResourceTile> createState() => _SwipeableResourceTileState();
}

class _SwipeableResourceTileState extends State<_SwipeableResourceTile> {
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
                _ResourceAction(
                  label: widget.savedView ? 'Remove' : 'Save',
                  iconAsset: widget.savedView
                      ? 'assets/removeiconup.png'
                      : null,
                  icon: widget.savedView ? null : Icons.favorite_border,
                  color: widget.savedView
                      ? const Color(0xFFE00019)
                      : const Color(0xFF3159B7),
                  onTap: () =>
                      _run(widget.savedView ? widget.onRemove : widget.onSave),
                ),
                const SizedBox(width: 8),
                _ResourceAction(
                  label: 'Get',
                  iconAsset: 'assets/downloadIcon.png',
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
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.resource.detailsWithoutSubject,
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

class ResourcePreviewThumbnail extends StatefulWidget {
  const ResourcePreviewThumbnail({super.key, required this.resource});

  final ResourceItem resource;

  @override
  State<ResourcePreviewThumbnail> createState() =>
      _ResourcePreviewThumbnailState();
}

class _ResourcePreviewThumbnailState extends State<ResourcePreviewThumbnail> {
  static final Map<String, Uint8List> _previewCache = {};
  late Future<Uint8List?> _preview;

  static const _fallback = Icon(
    Icons.picture_as_pdf_outlined,
    color: Color(0xFF777777),
    size: 25,
  );

  @override
  void initState() {
    super.initState();
    _preview = _loadPreview();
  }

  @override
  void didUpdateWidget(covariant ResourcePreviewThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resource.pdfUrl != widget.resource.pdfUrl) {
      _preview = _loadPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 66,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
      ),
      child: widget.resource.thumbnailUrl.isNotEmpty
          ? Image.network(
              widget.resource.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildAutomaticPreview(),
            )
          : _buildAutomaticPreview(),
    );
  }

  Widget _buildAutomaticPreview() {
    return FutureBuilder<Uint8List?>(
      future: _preview,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF08A948),
              ),
            ),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null) return _fallback;
        return Image.memory(bytes, fit: BoxFit.cover);
      },
    );
  }

  Future<Uint8List?> _loadPreview() async {
    final url = widget.resource.pdfUrl;
    if (url.isEmpty) return null;
    final cached = _previewCache[url];
    if (cached != null) return cached;

    PdfDocument? document;
    PdfPage? page;
    try {
      final pdfBytes = await InternetFile.get(url);
      document = await PdfDocument.openData(pdfBytes);
      page = await document.getPage(1);
      final image = await page.render(
        width: 180,
        height: 240,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      final bytes = image?.bytes;
      if (bytes != null) _previewCache[url] = bytes;
      return bytes;
    } catch (error) {
      debugPrint('Unable to create PDF preview: $error');
      return null;
    } finally {
      await page?.close();
      await document?.close();
    }
  }
}

class _ResourceAction extends StatelessWidget {
  const _ResourceAction({
    required this.label,
    this.iconAsset,
    this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String? iconAsset;
  final IconData? icon;
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
                child: iconAsset != null
                    ? Image.asset(iconAsset!, fit: BoxFit.contain)
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(icon, size: 17, color: Colors.white),
                      ),
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

class _NoSubjectResources extends StatelessWidget {
  const _NoSubjectResources({this.savedView = false});

  final bool savedView;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              savedView ? 'No saved resources yet' : 'No resources yet',
              style: GoogleFonts.lato(
                color: const Color(0xFF171717),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              savedView
                  ? 'Save a resource from the By Subject tab and it will appear here.'
                  : 'We’re adding resources to this subject. Check back soon for helpful activities, guides and learning materials.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: const Color(0xFF333333),
                fontSize: 16,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceLoadError extends StatelessWidget {
  const _ResourceLoadError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Text(
          'Resources could not be loaded. Please check your connection and try again.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            color: const Color(0xFF333333),
            fontSize: 16,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
