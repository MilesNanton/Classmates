import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/message_widget.dart';
import 'experience_image_widgets.dart';
import 'experience_metadata.dart';

class ExperienceDetailsScreen extends StatefulWidget {
  const ExperienceDetailsScreen({
    super.key,
    required this.experience,
    required this.initiallySaved,
    required this.onSavedChanged,
  });

  final Map<String, dynamic> experience;
  final bool initiallySaved;
  final ValueChanged<bool> onSavedChanged;

  @override
  State<ExperienceDetailsScreen> createState() =>
      _ExperienceDetailsScreenState();
}

class _ExperienceDetailsScreenState extends State<ExperienceDetailsScreen> {
  static const _green = Color(0xFF08A948);
  late bool _saved = widget.initiallySaved;

  Map<String, dynamic> get data => widget.experience;
  String _text(String key, [String fallback = '']) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String get _guidanceType {
    final guidance = _text('guidanceType');
    final fallbackType = _text('type');
    final value = guidance.isNotEmpty ? guidance : fallbackType;
    return value.toLowerCase() == 'guided' ? 'Guided' : 'Self-led';
  }

  List<String> get _descriptionPoints {
    final value = data['description'];
    final rawPoints = value is List
        ? value.map((item) => item.toString())
        : (value?.toString() ?? '').split(RegExp(r'\r?\n'));
    return rawPoints
        .map(
          (point) =>
              point.trim().replaceFirst(RegExp(r'^[\u2022\-*]\s*'), '').trim(),
        )
        .where((point) => point.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = _text('thumbnailUrl');
    final descriptionPoints = _descriptionPoints;
    final metadata = experienceMetadataValues(data);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leadingWidth: 76,
          leading: TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, size: 25),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF444444),
              padding: const EdgeInsets.only(left: 10),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Share experience',
              onPressed: _share,
              icon: const Icon(Icons.ios_share_outlined),
            ),
            IconButton(
              tooltip: _saved ? 'Remove from saved' : 'Save experience',
              onPressed: () {
                setState(() => _saved = !_saved);
                widget.onSavedChanged(_saved);
              },
              icon: Icon(
                _saved ? Icons.favorite : Icons.favorite_border,
                color: _saved ? _green : const Color(0xFF222222),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 34,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: double.infinity,
                        height: 220,
                        child: thumbnail.isEmpty
                            ? const ExperienceImageFallback(iconSize: 38)
                            : Image.network(
                                thumbnail,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const ExperienceImageFallback(iconSize: 38),
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                    ? child
                                    : const ExperienceImageSkeleton(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _text('name', 'Experience'),
                      style: GoogleFonts.lato(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hosted by ${_text('hostedBy', 'Event organiser')}',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: const Color(0xFF777777),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _text('schedule', 'Schedule to be confirmed'),
                      style: GoogleFonts.lato(fontSize: 14),
                    ),
                    if (_text('location').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _openLink(_text('location')),
                        child: Text(
                          'Get directions',
                          style: GoogleFonts.lato(
                            color: _green,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: _green,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      _guidanceType == 'Guided'
                          ? 'What to expect'
                          : "Try this while you're there",
                      style: GoogleFonts.lato(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (descriptionPoints.isEmpty)
                      Text(
                        'More information about this experience will be available soon.',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          height: 1.48,
                          color: const Color(0xFF6B6B6B),
                        ),
                      )
                    else
                      _BulletList(points: descriptionPoints),
                    const Spacer(),
                    const SizedBox(height: 22),
                    if (metadata.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: metadata
                              .map(
                                (value) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    child: _InfoTag(label: value),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE6E6E6))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _priceLabel,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _text('schedule', 'Schedule to be confirmed'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                FilledButton(
                  onPressed: _text('bookingLink').isEmpty
                      ? null
                      : () => _openLink(_text('bookingLink')),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9D9D9),
                    disabledForegroundColor: const Color(0xFF777777),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),
                  ),
                  child: const Text('Book'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _priceLabel {
    final freeValue = data['isFree'];
    if (freeValue == true ||
        freeValue.toString().trim().toLowerCase() == 'yes') {
      return 'Free';
    }
    if (freeValue == false ||
        freeValue.toString().trim().toLowerCase() == 'no') {
      return 'Paid';
    }
    final price = data['price'];
    if (price is! num || price == 0) return 'Free';
    return 'Paid';
  }

  Future<void> _openLink(String rawLink) async {
    final match = RegExp(r'https?://[^"\s]+').firstMatch(rawLink);
    final uri = Uri.tryParse(match?.group(0) ?? rawLink);
    try {
      if (uri != null &&
          await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        return;
      }
    } on PlatformException {
      // A newly added native plugin is unavailable until the iOS app has been
      // stopped and rebuilt. Keep the UI responsive and show a useful error.
    }
    if (!mounted) return;
    showMessagePopup(
      context,
      message: 'Unable to open this link.',
      type: MessageType.error,
    );
  }

  Future<void> _share() async {
    final bookingLink = _text('bookingLink');
    final content = [
      _text('name', 'Experience'),
      _text('schedule'),
      if (bookingLink.isNotEmpty) bookingLink,
    ].where((value) => value.isNotEmpty).join('\n');
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    showMessagePopup(
      context,
      message: 'Experience details copied to clipboard.',
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.points});

  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points
          .map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      height: 1.48,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        height: 1.48,
                        color: const Color(0xFF6B6B6B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    ),
  );
}
