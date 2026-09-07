import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/message_widget.dart';
import '../../widgets/screen_info_popup.dart';
import 'add_parents_screen.dart';
import 'setting_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onTabSelected});

  static const green = Color(0xFF0DA64A);
  final ValueChanged<int> onTabSelected;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showScreenInfoOnFirstVisit(context, ScreenInfoType.profile);
      }
    });
  }

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
              _ProfileHeader(
                onInfoPressed: () =>
                    showScreenInfoPopup(context, ScreenInfoType.profile),
              ),
              const Divider(height: 1, color: Color(0xFFEAEAEA)),
              Expanded(
                child: user == null
                    ? const _ProfileContent(
                        data: <String, dynamic>{},
                        userId: null,
                      )
                    : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (context, snapshot) => _ProfileContent(
                          userId: user.uid,
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
        bottomNavigationBar: _ProfileNavigation(onTap: widget.onTabSelected),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onInfoPressed});

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
              'Profile',
              style: GoogleFonts.lato(
                color: const Color(0xFF171717),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            ScreenInfoButton(onPressed: onInfoPressed),
            const SizedBox(width: 10),
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
  const _ProfileContent({required this.data, required this.userId});

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

  Color get avatarColor {
    const colors = [
      Color(0xFFEDF4FF),
      Color(0xFFE9FBF2),
      Color(0xFFF8EAFB),
      Color(0xFFFFF3E9),
    ];
    final index = (data['avatarColorIndex'] as num?)?.toInt() ?? 0;
    return colors[index.clamp(0, colors.length - 1)];
  }

  Color get avatarTextColor {
    const colors = [
      Color(0xFF317ABE),
      Color(0xFF00AD35),
      Color(0xFF8025C7),
      Color(0xFFEB6D00),
    ];
    final index = (data['avatarColorIndex'] as num?)?.toInt() ?? 0;
    return colors[index.clamp(0, colors.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: avatarColor,
              child: Text(
                _initials(name),
                style: GoogleFonts.lato(
                  color: avatarTextColor,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  curriculum,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFF5B5B5B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 42),
        _ExperiencesCard(userId: userId),
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
  const _ExperiencesCard({required this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    if (userId == null) return _buildEmptyCard(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('completedExperiences')
          .orderBy('completedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final experiences = snapshot.data?.docs ?? const [];
        if (experiences.isEmpty) return _buildEmptyCard(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExperiencesHeader(
              count: experiences.length,
              onAdd: () => _showAddExperienceSheet(context),
            ),
            const SizedBox(height: 8),
            ...experiences.map(
              (experience) => _CompletedExperienceRow(
                key: ValueKey(experience.id),
                userId: userId!,
                experienceId: experience.id,
                data: experience.data(),
                onRemove: () => experience.reference.delete(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCard(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ExperiencesHeader(
        count: 0,
        onAdd: userId == null ? null : () => _showAddExperienceSheet(context),
      ),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        height: 126,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          'Swipe left on an experience and tap Done when\nyou’ve explored it. It’ll then be added to your profile.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(fontSize: 13, height: 1.5),
        ),
      ),
    ],
  );

  Future<void> _showAddExperienceSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddExperienceSheet(userId: userId!),
      );
}

class _ExperiencesHeader extends StatelessWidget {
  const _ExperiencesHeader({required this.count, required this.onAdd});

  final int count;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Experiences ($count)',
          style: GoogleFonts.lato(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Material(
          color: ProfileScreen.green,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onAdd,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 28,
              height: 28,
              child: Icon(Icons.add, size: 21, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddExperienceSheet extends StatefulWidget {
  const _AddExperienceSheet({required this.userId});

  final String userId;

  @override
  State<_AddExperienceSheet> createState() => _AddExperienceSheetState();
}

class _AddExperienceSheetState extends State<_AddExperienceSheet> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _subjectController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    setState(() => _saving = true);
    try {
      final experience = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('completedExperiences')
          .doc();
      await experience.set({
        'experienceId': experience.id,
        'name': name,
        'hostedBy': _locationController.text.trim(),
        'location': _locationController.text.trim(),
        'subject': _subjectController.text.trim(),
        'category': _subjectController.text.trim(),
        'isCustom': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        showMessagePopupInOverlay(
          overlay,
          message: 'Experience added successfully.',
        );
      }
    } catch (_) {
      if (mounted) {
        showMessagePopup(
          context,
          message: 'Unable to save your experience. Try again.',
          type: MessageType.error,
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.465;
    final availableHeight = MediaQuery.sizeOf(context).height - keyboardInset;
    final effectiveSheetHeight = sheetHeight < availableHeight
        ? sheetHeight
        : availableHeight;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        height: effectiveSheetHeight,
        padding: const EdgeInsets.fromLTRB(27, 34, 27, 59),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Add your own experience',
                          style: GoogleFonts.lato(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        const CircleAvatar(
                          radius: 13,
                          backgroundColor: ProfileScreen.green,
                          child: Icon(Icons.add, size: 20, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    _ExperienceInput(
                      controller: _nameController,
                      hintText: 'Name of experience',
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 13),
                    _ExperienceInput(
                      controller: _locationController,
                      hintText: 'Location',
                    ),
                    const SizedBox(height: 13),
                    _ExperienceInput(
                      controller: _subjectController,
                      hintText: 'Subject',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed:
                            _nameController.text.trim().isEmpty || _saving
                            ? null
                            : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: ProfileScreen.green,
                          disabledBackgroundColor: const Color(0xFFB2B2B2),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save experience',
                                style: GoogleFonts.lato(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExperienceInput extends StatelessWidget {
  const _ExperienceInput({
    required this.controller,
    required this.hintText,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 51,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: GoogleFonts.lato(fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.lato(
            fontSize: 13,
            color: const Color(0xFF777777),
          ),
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _CompletedExperienceRow extends StatefulWidget {
  const _CompletedExperienceRow({
    super.key,
    required this.userId,
    required this.experienceId,
    required this.data,
    required this.onRemove,
  });

  final String userId;
  final String experienceId;
  final Map<String, dynamic> data;
  final Future<void> Function() onRemove;

  @override
  State<_CompletedExperienceRow> createState() =>
      _CompletedExperienceRowState();
}

class _CompletedExperienceRowState extends State<_CompletedExperienceRow> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final name = data['name']?.toString() ?? 'Experience';
    final host = data['hostedBy']?.toString() ?? '';
    final subject = data['subject']?.toString().trim() ?? '';
    final category = subject.isNotEmpty
        ? subject
        : data['category']?.toString().trim() ?? '';
    final hasNote =
        data['note'] is String && (data['note'] as String).trim().isNotEmpty;
    final hasPhoto =
        data['photoPath'] is String &&
        (data['photoPath'] as String).trim().isNotEmpty;
    return ClipRect(
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Material(
            color: const Color(0xFFE00014),
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: _removeExperience,
              child: const SizedBox(
                width: 76,
                height: 68,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, color: Colors.white, size: 20),
                    SizedBox(height: 4),
                    Text(
                      'Remove',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: GestureDetector(
              onHorizontalDragUpdate: (details) => setState(() {
                _dragOffset = (_dragOffset + details.delta.dx).clamp(-84, 0);
              }),
              onHorizontalDragEnd: (_) => setState(() {
                _dragOffset = _dragOffset < -35 ? -84 : 0;
              }),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 2,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE4E4E4))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.lato(
                              color: ProfileScreen.green,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (host.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              host,
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          if (category.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  height: 25,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFFD9D9D9),
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    category,
                                    style: GoogleFonts.lato(fontSize: 12),
                                  ),
                                ),
                                if (hasPhoto) ...[
                                  const SizedBox(width: 7),
                                  const _DocumentationIndicator.asset(
                                    'assets/iconflower.png',
                                  ),
                                ],
                                if (hasNote) ...[
                                  const SizedBox(width: 7),
                                  const _DocumentationIndicator.asset(
                                    'assets/note_icon.png',
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ExperienceAttachmentButton(
                      onTap: () => _showDocumentation(pickPhotoOnOpen: false),
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

  Future<void> _showDocumentation({required bool pickPhotoOnOpen}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        clipBehavior: Clip.antiAlias,
        builder: (_) => _ExperienceDocumentationSheet(
          userId: widget.userId,
          experienceId: widget.experienceId,
          experienceName: widget.data['name']?.toString() ?? 'Experience',
          initialNote: widget.data['note']?.toString() ?? '',
          initialPhotoPath: widget.data['photoPath']?.toString() ?? '',
          pickPhotoOnOpen: pickPhotoOnOpen,
        ),
      );

  Future<void> _removeExperience() async {
    try {
      final photoPath = widget.data['photoPath'];
      if (photoPath is String && photoPath.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(photoPath).delete();
        } catch (_) {
          // Continue removing the experience if its photo is already gone.
        }
      }
      await widget.onRemove();
      if (!mounted) return;
      showMessagePopup(
        context,
        message: 'Experience removed from your profile.',
      );
    } catch (_) {
      if (!mounted) return;
      showMessagePopup(
        context,
        message: 'Unable to remove the experience. Try again.',
        type: MessageType.error,
      );
    }
  }
}

class _ExperienceAttachmentButton extends StatelessWidget {
  const _ExperienceAttachmentButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Center(
          child: Image.asset(
            'assets/paperclipicon.png',
            width: 19,
            height: 19,
            fit: BoxFit.contain,
          ),
        ),
      ),
    ),
  );
}

class _DocumentationIndicator extends StatelessWidget {
  const _DocumentationIndicator({required this.icon}) : assetPath = null;

  const _DocumentationIndicator.asset(this.assetPath) : icon = null;

  final IconData? icon;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: assetPath != null
            ? Image.asset(
                assetPath!,
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              )
            : Icon(icon, color: Colors.black, size: 15),
      ),
    );
  }
}

class _ExperienceDocumentationSheet extends StatefulWidget {
  const _ExperienceDocumentationSheet({
    required this.userId,
    required this.experienceId,
    required this.experienceName,
    required this.initialNote,
    required this.initialPhotoPath,
    required this.pickPhotoOnOpen,
  });

  final String userId;
  final String experienceId;
  final String experienceName;
  final String initialNote;
  final String initialPhotoPath;
  final bool pickPhotoOnOpen;

  @override
  State<_ExperienceDocumentationSheet> createState() =>
      _ExperienceDocumentationSheetState();
}

class _ExperienceDocumentationSheetState
    extends State<_ExperienceDocumentationSheet> {
  late final TextEditingController _noteController;
  XFile? _selectedPhoto;
  Uint8List? _selectedPhotoBytes;
  Uint8List? _existingPhotoBytes;
  late bool _keepExistingPhoto;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
    _keepExistingPhoto = widget.initialPhotoPath.isNotEmpty;
    if (_keepExistingPhoto) _loadExistingPhoto();
    if (widget.pickPhotoOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickPhoto());
    }
  }

  Future<void> _loadExistingPhoto() async {
    try {
      final bytes = await FirebaseStorage.instance
          .ref(widget.initialPhotoPath)
          .getData(10 * 1024 * 1024);
      if (mounted) setState(() => _existingPhotoBytes = bytes);
    } catch (_) {
      // Keep the attachment available if its preview cannot load.
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedPhoto = photo;
      _selectedPhotoBytes = bytes;
      _keepExistingPhoto = false;
    });
  }

  void _removePhoto() => setState(() {
    _selectedPhoto = null;
    _selectedPhotoBytes = null;
    _keepExistingPhoto = false;
  });

  Future<void> _save() async {
    if (_saving) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    setState(() => _saving = true);
    Reference? newPhotoReference;
    try {
      var photoPath = _keepExistingPhoto ? widget.initialPhotoPath : '';
      final photo = _selectedPhoto;
      final photoBytes = _selectedPhotoBytes;
      if (photo != null && photoBytes != null) {
        final extension = photo.name.contains('.')
            ? photo.name.split('.').last.toLowerCase()
            : 'jpg';
        newPhotoReference = FirebaseStorage.instance.ref(
          'users/${widget.userId}/experienceDocumentation/'
          '${widget.experienceId}/photo_${DateTime.now().millisecondsSinceEpoch}.$extension',
        );
        await newPhotoReference.putData(
          photoBytes,
          SettableMetadata(contentType: photo.mimeType ?? 'image/jpeg'),
        );
        photoPath = newPhotoReference.fullPath;
      }

      final note = _noteController.text.trim();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('completedExperiences')
          .doc(widget.experienceId)
          .update({
            'note': note.isEmpty ? FieldValue.delete() : note,
            'photoPath': photoPath.isEmpty ? FieldValue.delete() : photoPath,
            'documentationUpdatedAt': FieldValue.serverTimestamp(),
          });

      if (widget.initialPhotoPath.isNotEmpty &&
          widget.initialPhotoPath != photoPath) {
        try {
          await FirebaseStorage.instance.ref(widget.initialPhotoPath).delete();
        } catch (_) {
          // The updated document no longer references the old photo.
        }
      }
      if (mounted) {
        Navigator.pop(context);
        showMessagePopupInOverlay(
          overlay,
          message: 'Documentation saved successfully.',
        );
      }
    } catch (_) {
      if (newPhotoReference != null) {
        try {
          await newPhotoReference.delete();
        } catch (_) {
          // Best-effort cleanup after a failed save.
        }
      }
      if (mounted) {
        showMessagePopup(
          context,
          message: 'Unable to save your note and photo. Try again.',
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasPhoto = _selectedPhotoBytes != null || _keepExistingPhoto;
    final canSave = _noteController.text.trim().isNotEmpty && !_saving;
    final sheetHeight =
        MediaQuery.sizeOf(context).height * (hasPhoto ? 0.60 : 0.475);
    final availableHeight = MediaQuery.sizeOf(context).height - bottomInset;
    final effectiveSheetHeight = bottomInset > 0
        ? availableHeight
        : sheetHeight;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: effectiveSheetHeight,
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 51),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Document this experience',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Image.asset(
                  'assets/paperclipicon.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              widget.experienceName,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: const Color(0xFF707070),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: hasPhoto ? 108 : 126,
              child: TextField(
                controller: _noteController,
                onChanged: (_) => setState(() {}),
                expands: true,
                minLines: null,
                maxLines: null,
                maxLength: 1000,
                style: GoogleFonts.lato(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  hintStyle: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFF171717),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: Color(0xFFDADADA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: Color(0xFFDADADA)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (hasPhoto) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 128,
                  child: _selectedPhotoBytes != null
                      ? Image.memory(_selectedPhotoBytes!, fit: BoxFit.cover)
                      : _existingPhotoBytes != null
                      ? Image.memory(_existingPhotoBytes!, fit: BoxFit.cover)
                      : const Center(
                          child: CircularProgressIndicator(
                            color: ProfileScreen.green,
                            strokeWidth: 2,
                          ),
                        ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 26,
                  child: TextButton.icon(
                    onPressed: _removePhoto,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 15),
                    label: const Text(
                      'Remove photo',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
            ] else
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF171717),
                    side: const BorderSide(color: Color(0xFFDADADA)),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  icon: Image.asset(
                    'assets/pictureIocn.png',
                    width: 19,
                    height: 19,
                    fit: BoxFit.contain,
                  ),
                  label: Text(
                    'Add one photo',
                    style: GoogleFonts.lato(fontSize: 14),
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: canSave ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: ProfileScreen.green,
                  disabledBackgroundColor: const Color(0xFFB2B2B2),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save documentation',
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
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
    ('assets/experienceIconUpdated.png', 'Experiences'),
    ('assets/calenderIcon.png', 'Timetable'),
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
                        fontWeight: index == 4
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
