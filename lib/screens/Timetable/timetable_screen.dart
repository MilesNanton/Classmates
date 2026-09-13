import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/message_widget.dart';
import '../../widgets/screen_info_popup.dart';
import '../Experiences/experience_details_screen.dart';
import '../Profile/setting_screen.dart';
import 'subject_progress_screen.dart';

Future<void> showExperienceTimetablePopup(
  BuildContext context, {
  required String experienceId,
  required String title,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final entry = await showModalBottomSheet<_TimetableEntry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black45,
    builder: (_) => _TimetableEntrySheet(
      category: 'Other',
      heading: 'Add to timetable',
      initialTitle: title,
      titleLocked: true,
      upcomingOnly: true,
    ),
  );
  if (entry == null) return;
  final document = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('timetableEntries')
      .doc();
  try {
    await document.set({
      'entryId': document.id,
      'category': entry.category,
      'title': entry.title,
      'type': entry.type.name,
      'days': entry.days,
      'date': Timestamp.fromDate(entry.date),
      'startMinutes': entry.start.hour * 60 + entry.start.minute,
      'endMinutes': entry.end.hour * 60 + entry.end.minute,
      'recurring': entry.recurring,
      'experienceId': experienceId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    showMessagePopupInOverlay(
      overlay,
      message: 'Experience added to your timetable.',
    );
  } on FirebaseException {
    showMessagePopupInOverlay(
      overlay,
      message: 'Could not add experience to timetable.',
      type: MessageType.error,
    );
  }
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({
    super.key,
    required this.onTabSelected,
    this.initialSelectedDate,
    this.initialSelectedChild = 1,
    this.onDateChanged,
    this.onChildChanged,
  });

  final ValueChanged<int> onTabSelected;
  final DateTime? initialSelectedDate;
  final int initialSelectedChild;
  final ValueChanged<DateTime>? onDateChanged;
  final ValueChanged<int>? onChildChanged;

  static const _green = Color(0xFF00AD4D);

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late DateTime _selectedDate;
  bool _showAddChoices = false;
  bool _showSubjectHint = true;
  late int _selectedChild;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(
      widget.initialSelectedDate ?? DateTime.now(),
    );
    _selectedChild = widget.initialSelectedChild;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showScreenInfoOnFirstVisit(context, ScreenInfoType.timetable);
      }
    });
  }

  Future<void> _openAddScreen({
    required bool isSubject,
    required int childNumber,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = await showModalBottomSheet<_TimetableEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      builder: (_) => _TimetableEntrySheet(
        category: isSubject ? 'Subject' : 'Other',
        heading: isSubject ? 'Add a subject' : 'Add to timetable',
        subjectMode: isSubject,
        childNumber: childNumber,
      ),
    );
    if (entry == null || !mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final document = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('timetableEntries')
        .doc();
    try {
      await document.set({
        'entryId': document.id,
        'category': entry.category,
        'title': entry.title,
        'type': entry.type.name,
        'days': entry.days,
        'date': Timestamp.fromDate(entry.date),
        'startMinutes': entry.start.hour * 60 + entry.start.minute,
        'endMinutes': entry.end.hour * 60 + entry.end.minute,
        'recurring': entry.recurring,
        'childNumber': childNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() {
          _selectedDate = entry.date;
          _showAddChoices = false;
        });
        widget.onDateChanged?.call(entry.date);
        showMessagePopupInOverlay(
          overlay,
          message: 'Timetable entry added successfully.',
        );
      }
    } on FirebaseException {
      if (!mounted) return;
      showMessagePopupInOverlay(
        overlay,
        message: 'Could not save timetable entry.',
        type: MessageType.error,
      );
    }
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
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: user == null
                ? null
                : FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
            builder: (context, profileSnapshot) {
              final storedCount = profileSnapshot.data?.data()?['childCount'];
              final childCount = storedCount is num
                  ? storedCount.toInt().clamp(1, 4)
                  : 1;
              final activeChild = _selectedChild.clamp(1, childCount);
              return Column(
                children: [
                  _Header(
                    childCount: childCount,
                    selectedChild: activeChild,
                    onChildSelected: (child) => setState(() {
                      _selectedChild = child;
                      _showAddChoices = false;
                      widget.onChildChanged?.call(child);
                    }),
                    onInfoPressed: () =>
                        showScreenInfoPopup(context, ScreenInfoType.timetable),
                  ),
                  const Divider(height: 1, color: Color(0xFFEAEAEA)),
                  _DateStrip(
                    selectedDate: _selectedDate,
                    onSelected: (date) {
                      setState(() => _selectedDate = date);
                      widget.onDateChanged?.call(date);
                    },
                  ),
                  Expanded(
                    child: _TimetableEntries(
                      childNumber: activeChild,
                      selectedDate: _selectedDate,
                      showSubjectHint: _showSubjectHint,
                      onCloseSubjectHint: () =>
                          setState(() => _showSubjectHint = false),
                      showAddChoices: _showAddChoices,
                      onAdd: () => setState(() => _showAddChoices = true),
                      onAddSubject: () => runWithSubscriptionAccess(
                        context,
                        () => _openAddScreen(
                          isSubject: true,
                          childNumber: activeChild,
                        ),
                      ),
                      onAddOther: () => runWithSubscriptionAccess(
                        context,
                        () => _openAddScreen(
                          isSubject: false,
                          childNumber: activeChild,
                        ),
                      ),
                      onCloseAddChoices: () =>
                          setState(() => _showAddChoices = false),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: _TimetableNavigation(onTap: widget.onTabSelected),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.childCount,
    required this.selectedChild,
    required this.onChildSelected,
    required this.onInfoPressed,
  });

  final int childCount;
  final int selectedChild;
  final ValueChanged<int> onChildSelected;
  final VoidCallback onInfoPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 18, 14),
      child: Row(
        children: [
          Text(
            'Timetable',
            style: GoogleFonts.lato(
              color: const Color(0xFF171717),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          if (childCount > 1) ...[
            PopupMenuButton<int>(
              initialValue: selectedChild,
              onSelected: onChildSelected,
              position: PopupMenuPosition.under,
              tooltip: 'Switch timetable',
              itemBuilder: (_) => List.generate(
                childCount,
                (index) => PopupMenuItem<int>(
                  value: index + 1,
                  child: Text('Child ${index + 1}'),
                ),
              ),
              child: Container(
                height: 42,
                padding: const EdgeInsets.only(left: 17, right: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: TimetableScreen._green, width: 2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Child $selectedChild',
                      style: GoogleFonts.lato(
                        color: const Color(0xFF171717),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: TimetableScreen._green,
                      size: 23,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          ScreenInfoButton(onPressed: onInfoPressed),
        ],
      ),
    ),
  );
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.selectedDate, required this.onSelected});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SizedBox(
      height: 74,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final date = today.add(Duration(days: index));
          return _DateChip(
            date: date,
            selected: DateUtils.isSameDay(date, selectedDate),
            onTap: () => onSelected(DateUtils.dateOnly(date)),
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_weekdays[date.weekday - 1]} '
        '${date.day}${_suffix(date.day)} ${_months[date.month - 1]}';
    final today = DateUtils.isSameDay(date, DateTime.now());
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFF4F9F6),
          borderRadius: BorderRadius.circular(24),
          border: selected
              ? Border.all(color: TimetableScreen._green, width: 2)
              : null,
        ),
        child: Text(
          today ? '(Today) $dateText' : dateText,
          style: GoogleFonts.lato(
            color: TimetableScreen._green,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static String _suffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    return switch (day % 10) {
      1 => 'st',
      2 => 'nd',
      3 => 'rd',
      _ => 'th',
    };
  }
}

class _EmptyTimetable extends StatelessWidget {
  const _EmptyTimetable({
    required this.onAdd,
    required this.showAddChoices,
    required this.onAddSubject,
    required this.onAddOther,
    required this.onCloseAddChoices,
  });

  final VoidCallback onAdd;
  final bool showAddChoices;
  final VoidCallback onAddSubject;
  final VoidCallback onAddOther;
  final VoidCallback onCloseAddChoices;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(34, 158, 34, 20),
    child: Column(
      children: [
        Text(
          'Your timetable',
          style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          'Add subjects, activities, clubs and regular routines\nto your timetable.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            color: const Color(0xFF777777),
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const Spacer(),
        _AddTimetableButtons(
          expanded: showAddChoices,
          onAdd: onAdd,
          onAddSubject: onAddSubject,
          onAddOther: onAddOther,
          onClose: onCloseAddChoices,
        ),
      ],
    ),
  );
}

class _TimetableEntries extends StatelessWidget {
  const _TimetableEntries({
    required this.childNumber,
    required this.selectedDate,
    required this.showSubjectHint,
    required this.onCloseSubjectHint,
    required this.onAdd,
    required this.showAddChoices,
    required this.onAddSubject,
    required this.onAddOther,
    required this.onCloseAddChoices,
  });

  final int childNumber;
  final DateTime selectedDate;
  final bool showSubjectHint;
  final VoidCallback onCloseSubjectHint;
  final VoidCallback onAdd;
  final bool showAddChoices;
  final VoidCallback onAddSubject;
  final VoidCallback onAddOther;
  final VoidCallback onCloseAddChoices;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _EmptyTimetable(
        onAdd: onAdd,
        showAddChoices: showAddChoices,
        onAddSubject: onAddSubject,
        onAddOther: onAddOther,
        onCloseAddChoices: onCloseAddChoices,
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('timetableEntries')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not load your timetable.',
              style: GoogleFonts.lato(color: const Color(0xFF777777)),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: TimetableScreen._green,
              strokeWidth: 2,
            ),
          );
        }
        final entries =
            snapshot.data!.docs
                .map(_TimetableEntry.fromDocument)
                .where(
                  (entry) =>
                      entry.childNumber == childNumber &&
                      (DateUtils.isSameDay(entry.date, selectedDate) ||
                          (entry.type == _EntryType.regular &&
                              entry.recurring &&
                              entry.days.contains(
                                _weekdayName(selectedDate.weekday),
                              ) &&
                              !selectedDate.isBefore(entry.date))),
                )
                .toList()
              ..sort((a, b) {
                final aMinutes = a.start.hour * 60 + a.start.minute;
                final bMinutes = b.start.hour * 60 + b.start.minute;
                return aMinutes.compareTo(bMinutes);
              });
        return _TimetableContent(
          entries: entries,
          selectedDate: selectedDate,
          showSubjectHint: showSubjectHint,
          onCloseSubjectHint: onCloseSubjectHint,
          onAdd: onAdd,
          showAddChoices: showAddChoices,
          onAddSubject: onAddSubject,
          onAddOther: onAddOther,
          onCloseAddChoices: onCloseAddChoices,
        );
      },
    );
  }

  static String _weekdayName(int weekday) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][weekday - 1];
}

class _TimetableContent extends StatelessWidget {
  const _TimetableContent({
    required this.entries,
    required this.selectedDate,
    required this.showSubjectHint,
    required this.onCloseSubjectHint,
    required this.onAdd,
    required this.showAddChoices,
    required this.onAddSubject,
    required this.onAddOther,
    required this.onCloseAddChoices,
  });

  final List<_TimetableEntry> entries;
  final DateTime selectedDate;
  final bool showSubjectHint;
  final VoidCallback onCloseSubjectHint;
  final VoidCallback onAdd;
  final bool showAddChoices;
  final VoidCallback onAddSubject;
  final VoidCallback onAddOther;
  final VoidCallback onCloseAddChoices;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyTimetable(
        onAdd: onAdd,
        showAddChoices: showAddChoices,
        onAddSubject: onAddSubject,
        onAddOther: onAddOther,
        onCloseAddChoices: onCloseAddChoices,
      );
    }
    final showHint =
        showSubjectHint && entries.any((entry) => entry.category == 'Subject');
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 12, 20, showHint ? 154 : 68),
            children: entries
                .map(
                  (entry) => _SwipeableTimetableEntry(
                    entry: entry,
                    child: _TimetableEntryCard(
                      entry: entry,
                      selectedDate: selectedDate,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHint) ...[
                _SubjectHint(onClose: onCloseSubjectHint),
                const SizedBox(height: 18),
              ],
              _AddTimetableButtons(
                expanded: showAddChoices,
                onAdd: onAdd,
                onAddSubject: onAddSubject,
                onAddOther: onAddOther,
                onClose: onCloseAddChoices,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubjectHint extends StatelessWidget {
  const _SubjectHint({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFD8D8D8)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Tap a subject to see what your child\ncan work towards.',
            style: GoogleFonts.lato(
              color: const Color(0xFF777777),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
        TextButton(
          onPressed: onClose,
          child: Text(
            'Close',
            style: GoogleFonts.lato(
              color: TimetableScreen._green,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AddTimetableButtons extends StatelessWidget {
  const _AddTimetableButtons({
    required this.expanded,
    required this.onAdd,
    required this.onAddSubject,
    required this.onAddOther,
    required this.onClose,
  });

  final bool expanded;
  final VoidCallback onAdd;
  final VoidCallback onAddSubject;
  final VoidCallback onAddOther;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF171717),
      side: const BorderSide(color: TimetableScreen._green),
      shape: const StadiumBorder(),
      textStyle: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w700),
    );
    if (!expanded) {
      return OutlinedButton(
        onPressed: onAdd,
        style: buttonStyle,
        child: const Text('Add to timetable'),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: onAddSubject,
          style: buttonStyle,
          child: const Text('Add a Subject'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: onAddOther,
          style: buttonStyle,
          child: const Text('Add Other'),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close, size: 18),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFF171717),
            side: const BorderSide(color: Color(0xFFE1E1E1)),
            shape: const CircleBorder(),
            fixedSize: const Size(36, 36),
          ),
        ),
      ],
    );
  }
}

class _SwipeableTimetableEntry extends StatefulWidget {
  const _SwipeableTimetableEntry({required this.entry, required this.child});

  final _TimetableEntry entry;
  final Widget child;

  @override
  State<_SwipeableTimetableEntry> createState() =>
      _SwipeableTimetableEntryState();
}

class _SwipeableTimetableEntryState extends State<_SwipeableTimetableEntry> {
  static const _actionsWidth = 170.0;
  double _offset = 0;

  DocumentReference<Map<String, dynamic>>? get _document {
    final user = FirebaseAuth.instance.currentUser;
    final entryId = widget.entry.id;
    if (user == null || entryId == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('timetableEntries')
        .doc(entryId);
  }

  Future<void> _remove() async {
    setState(() => _offset = 0);
    final document = _document;
    if (document == null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    try {
      await document.delete();
      showMessagePopupInOverlay(
        overlay,
        message: 'Timetable entry removed successfully.',
      );
    } on FirebaseException {
      showMessagePopupInOverlay(
        overlay,
        message: 'Could not remove timetable entry.',
        type: MessageType.error,
      );
    }
  }

  Future<void> _edit() async {
    setState(() => _offset = 0);
    final overlay = Overlay.of(context, rootOverlay: true);
    final updated = await showModalBottomSheet<_TimetableEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      builder: (_) => _TimetableEntrySheet(
        category: widget.entry.category,
        heading: 'Edit timetable',
        initialEntry: widget.entry,
        titleLocked: widget.entry.experienceId != null,
        upcomingOnly: widget.entry.experienceId != null,
        childNumber: widget.entry.childNumber,
      ),
    );
    final document = _document;
    if (updated == null || document == null) return;
    try {
      await document.update({
        'title': updated.title,
        'type': updated.type.name,
        'days': updated.days,
        'date': Timestamp.fromDate(updated.date),
        'startMinutes': updated.start.hour * 60 + updated.start.minute,
        'endMinutes': updated.end.hour * 60 + updated.end.minute,
        'recurring': updated.recurring,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      showMessagePopupInOverlay(
        overlay,
        message: 'Timetable entry updated successfully.',
      );
    } on FirebaseException {
      showMessagePopupInOverlay(
        overlay,
        message: 'Could not update timetable entry.',
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          if (_offset < -0.5)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: _actionsWidth,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 0, 2),
                child: Row(
                  children: [
                    Expanded(
                      child: _TimetableSwipeAction(
                        asset: 'assets/editIconup.png',
                        label: 'Edit',
                        color: const Color(0xFFAAAAAA),
                        onTap: _edit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TimetableSwipeAction(
                        asset: 'assets/removeIcon.png',
                        label: 'Remove',
                        color: const Color(0xFFD90018),
                        onTap: _remove,
                      ),
                    ),
                  ],
                ),
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
              child: ColoredBox(color: Colors.white, child: widget.child),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TimetableSwipeAction extends StatelessWidget {
  const _TimetableSwipeAction({
    this.icon,
    this.asset,
    required this.label,
    required this.color,
    required this.onTap,
  }) : assert(icon != null || asset != null);

  final IconData? icon;
  final String? asset;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(6),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (asset != null)
            Image.asset(asset!, width: 21, height: 21, fit: BoxFit.contain)
          else
            Icon(icon, color: Colors.white, size: 21),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.lato(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _TimetableEntryCard extends StatelessWidget {
  const _TimetableEntryCard({required this.entry, required this.selectedDate});

  final _TimetableEntry entry;
  final DateTime selectedDate;

  Future<void> _openExperience(BuildContext context) async {
    final experienceId = entry.experienceId;
    if (experienceId == null) return;
    try {
      final document = await FirebaseFirestore.instance
          .collection('experiences')
          .doc(experienceId)
          .get();
      if (!context.mounted) return;
      if (!document.exists || document.data() == null) {
        showMessagePopup(
          context,
          message: 'This experience is no longer available.',
          type: MessageType.error,
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ExperienceDetailsScreen(
            experience: document.data()!,
            initiallySaved: false,
            onSavedChanged: (_) {},
          ),
        ),
      );
    } on FirebaseException {
      if (!context.mounted) return;
      showMessagePopup(
        context,
        message: 'Could not open the experience details.',
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<DateTime>(
    initialData: DateTime.now(),
    stream: Stream<DateTime>.periodic(
      const Duration(seconds: 15),
      (_) => DateTime.now(),
    ),
    builder: (context, snapshot) {
      final now = snapshot.data ?? DateTime.now();
      final start = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        entry.start.hour,
        entry.start.minute,
      );
      var end = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        entry.end.hour,
        entry.end.minute,
      );
      if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
      final active =
          DateUtils.isSameDay(selectedDate, now) &&
          !now.isBefore(start) &&
          now.isBefore(end);
      final isExperience = entry.experienceId != null;
      final isSubject = entry.category == 'Subject';
      return Material(
        color: Colors.white,
        child: InkWell(
          onTap: isExperience
              ? () => _openExperience(context)
              : isSubject
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SubjectProgressScreen(
                      subject: entry.title,
                      entryId: entry.id,
                      childNumber: entry.childNumber,
                    ),
                  ),
                )
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: isExperience ? 14 : 24,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: active
                    ? TimetableScreen._green
                    : const Color(0xFFE1E1E1),
                width: active ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: isExperience
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  color: const Color(0xFF9145F5),
                                  child: Text(
                                    'Experience',
                                    style: GoogleFonts.lato(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Tap here for details',
                                  style: GoogleFonts.lato(
                                    color: const Color(0xFF777777),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entry.title,
                              style: GoogleFonts.lato(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        )
                      : isSubject
                      ? _SubjectTimetableTitle(entry: entry)
                      : Text(
                          entry.title,
                          style: GoogleFonts.lato(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                Text(
                  '${_displayTime(entry.start)} - ${_displayTime(entry.end)}',
                  style: GoogleFonts.lato(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  static String _displayTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute == 0
        ? ''
        : ':${time.minute.toString().padLeft(2, '0')}';
    return '$hour$minute${time.period == DayPeriod.am ? 'am' : 'pm'}';
  }
}

class _SubjectTimetableTitle extends StatelessWidget {
  const _SubjectTimetableTitle({required this.entry});

  final _TimetableEntry entry;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final entryId = entry.id;
    if (user == null || entryId == null) return _title();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('subjectProgress')
          .doc(entryId)
          .snapshots(),
      builder: (context, snapshot) {
        final statuses = snapshot.data?.data()?['topicStatuses'];
        String? learningTopic;
        if (statuses is Map) {
          for (final status in statuses.entries) {
            if (status.value == 'learning') {
              final topicId = '${status.key}';
              learningTopic = topicId.contains('/')
                  ? topicId.substring(topicId.indexOf('/') + 1)
                  : topicId;
              break;
            }
          }
        }
        return _title(learningTopic);
      },
    );
  }

  Widget _title([String? learningTopic]) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        entry.title,
        style: GoogleFonts.lato(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      if (learningTopic != null) ...[
        const SizedBox(height: 4),
        Text(
          learningTopic,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.lato(color: const Color(0xFF777777), fontSize: 14),
        ),
      ],
    ],
  );
}

class _TimetableEntry {
  const _TimetableEntry({
    this.id,
    this.experienceId,
    required this.category,
    required this.title,
    required this.start,
    required this.end,
    required this.type,
    required this.days,
    required this.date,
    required this.recurring,
    this.childNumber = 1,
  });

  final String? id;
  final String? experienceId;
  final String category;
  final String title;
  final TimeOfDay start;
  final TimeOfDay end;
  final _EntryType type;
  final List<String> days;
  final DateTime date;
  final bool recurring;
  final int childNumber;

  factory _TimetableEntry.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final typeName = data['type'];
    final startMinutes = data['startMinutes'] is int
        ? data['startMinutes'] as int
        : 0;
    final endMinutes = data['endMinutes'] is int
        ? data['endMinutes'] as int
        : 0;
    final storedDate = data['date'];
    return _TimetableEntry(
      id: document.id,
      experienceId:
          data['experienceId'] is String &&
              (data['experienceId'] as String).isNotEmpty
          ? data['experienceId'] as String
          : null,
      category: data['category'] is String ? data['category'] as String : '',
      title: data['title'] is String ? data['title'] as String : '',
      start: TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60),
      end: TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60),
      type: typeName == _EntryType.upcoming.name
          ? _EntryType.upcoming
          : _EntryType.regular,
      days: data['days'] is Iterable
          ? (data['days'] as Iterable).whereType<String>().toList()
          : data['day'] is String
          ? [data['day'] as String]
          : const ['Monday'],
      date: storedDate is Timestamp
          ? DateUtils.dateOnly(storedDate.toDate())
          : DateUtils.dateOnly(DateTime.now()),
      recurring: data['recurring'] == true,
      childNumber: data['childNumber'] is num
          ? (data['childNumber'] as num).toInt()
          : 1,
    );
  }
}

enum _EntryType { regular, upcoming }

class _TimetableEntrySheet extends StatefulWidget {
  const _TimetableEntrySheet({
    required this.category,
    this.heading,
    this.initialEntry,
    this.initialTitle,
    this.titleLocked = false,
    this.upcomingOnly = false,
    this.subjectMode = false,
    this.childNumber = 1,
  });

  final String category;
  final String? heading;
  final _TimetableEntry? initialEntry;
  final String? initialTitle;
  final bool titleLocked;
  final bool upcomingOnly;
  final bool subjectMode;
  final int childNumber;

  @override
  State<_TimetableEntrySheet> createState() => _TimetableEntrySheetState();
}

class _TimetableEntrySheetState extends State<_TimetableEntrySheet> {
  static const _subjects = [
    'English',
    'Mathematics',
    'Science',
    'History',
    'Geography',
    'Music',
    'Art & Design',
  ];
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final _titleController = TextEditingController();
  final Set<String> _selectedDays = {'Monday'};
  _EntryType _type = _EntryType.regular;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  bool _repeat = true;
  bool _hasConflict = false;
  bool _checkingConflict = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEntry;
    if (initial != null) {
      _titleController.text = initial.title;
      _selectedDays
        ..clear()
        ..addAll(initial.days.isEmpty ? const ['Monday'] : initial.days);
      _type = initial.type;
      _start = initial.start;
      _end = initial.end;
      _date = initial.date;
      _repeat = initial.recurring;
    } else if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.upcomingOnly) _type = _EntryType.upcoming;
    _titleController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _titleController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool start}) async {
    final initialTime = start ? _start : _end;
    var selectedTime = _nearestQuarterHour(initialTime);
    final selected = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: Colors.black45,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (pickerContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(pickerContext),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF9B9B9B)),
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      onPressed: () =>
                          Navigator.pop(pickerContext, selectedTime),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E5E5)),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime(
                    2026,
                    1,
                    1,
                    selectedTime.hour,
                    selectedTime.minute,
                  ),
                  minuteInterval: 15,
                  onDateTimeChanged: (dateTime) {
                    selectedTime = TimeOfDay.fromDateTime(dateTime);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _hasConflict = false;
      if (start) {
        _start = selected;
        _end = _oneHourAfter(selected);
      } else {
        _end = selected;
      }
    });
  }

  TimeOfDay _oneHourAfter(TimeOfDay time) => TimeOfDay(
    hour: (time.hour + 1) % TimeOfDay.hoursPerDay,
    minute: time.minute,
  );

  TimeOfDay _nearestQuarterHour(TimeOfDay time) {
    final roundedMinutes = ((time.hour * 60 + time.minute + 7) ~/ 15) * 15;
    return TimeOfDay(
      hour: (roundedMinutes ~/ 60) % TimeOfDay.hoursPerDay,
      minute: roundedMinutes % 60,
    );
  }

  String _timeText(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickSubject() async {
    var selected = _titleController.text.isEmpty
        ? _subjects.first
        : _titleController.text;
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (pickerContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              SizedBox(
                height: 54,
                child: Row(
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(pickerContext),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      onPressed: () => Navigator.pop(pickerContext, selected),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: CupertinoColors.systemBlue),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  scrollController: FixedExtentScrollController(
                    initialItem: _subjects
                        .indexOf(selected)
                        .clamp(0, _subjects.length - 1),
                  ),
                  onSelectedItemChanged: (index) => selected = _subjects[index],
                  children: _subjects
                      .map((subject) => Center(child: Text(subject)))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (value != null && mounted) _titleController.text = value;
  }

  DateTime _regularDate() {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDay = _selectedDays.isEmpty ? 'Monday' : _selectedDays.first;
    final targetWeekday = _days.indexOf(firstDay) + 1;
    return today.add(Duration(days: (targetWeekday - today.weekday) % 7));
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (title.isEmpty || user == null || _checkingConflict) return;
    final entryDate = _type == _EntryType.upcoming ? _date : _regularDate();
    setState(() => _checkingConflict = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('timetableEntries')
          .where('date', isEqualTo: Timestamp.fromDate(entryDate))
          .get();
      final startMinutes = _start.hour * 60 + _start.minute;
      final endMinutes = _end.hour * 60 + _end.minute;
      final conflict = snapshot.docs.any((document) {
        if (document.id == widget.initialEntry?.id) return false;
        final data = document.data();
        final storedStart = data['startMinutes'];
        final storedEnd = data['endMinutes'];
        return storedStart is int &&
            storedEnd is int &&
            startMinutes < storedEnd &&
            endMinutes > storedStart;
      });
      if (!mounted) return;
      if (conflict) {
        setState(() {
          _hasConflict = true;
          _checkingConflict = false;
        });
        return;
      }
    } on FirebaseException {
      if (!mounted) return;
      setState(() => _checkingConflict = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check your timetable.')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      _TimetableEntry(
        category: widget.category,
        title: title,
        start: _start,
        end: _end,
        type: _type,
        days: _type == _EntryType.regular ? _selectedDays.toList() : const [],
        date: entryDate,
        recurring: _type == _EntryType.regular && _repeat,
        childNumber: widget.childNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = screenHeight * 0.80;
    final keyboardOpen = keyboardInset > 0;
    final canSubmit =
        _titleController.text.trim().isNotEmpty && !_checkingConflict;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: sheetHeight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  28,
                  keyboardOpen ? 18 : 42,
                  28,
                  keyboardOpen ? 16 : 28,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 34,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            widget.heading ?? widget.category,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton.outlined(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, size: 17),
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                minimumSize: const Size(32, 32),
                                maximumSize: const Size(32, 32),
                                side: const BorderSide(
                                  color: Color(0xFFE1E1E1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: keyboardOpen ? 14 : 38),
                    TextField(
                      controller: _titleController,
                      readOnly: widget.titleLocked || widget.subjectMode,
                      onTap: widget.subjectMode ? _pickSubject : null,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      style: GoogleFonts.lato(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: widget.subjectMode
                            ? 'Select a subject'
                            : 'Title',
                        hintStyle: GoogleFonts.lato(
                          color: widget.subjectMode
                              ? TimetableScreen._green
                              : const Color(0xFF858585),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF6F6F8),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 14,
                        ),
                      ),
                    ),
                    if (_type == _EntryType.upcoming) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: keyboardOpen ? 260 : 300,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: TimetableScreen._green,
                              onPrimary: Colors.white,
                            ),
                          ),
                          child: CalendarDatePicker(
                            initialDate: _date,
                            firstDate: DateUtils.dateOnly(DateTime.now()),
                            lastDate: DateTime(DateTime.now().year + 5),
                            onDateChanged: (date) => setState(() {
                              _date = DateUtils.dateOnly(date);
                              _hasConflict = false;
                            }),
                          ),
                        ),
                      ),
                    ],
                    if (_type == _EntryType.regular) ...[
                      SizedBox(height: keyboardOpen ? 12 : 22),
                      Row(
                        children: [
                          Text('Repeat', style: GoogleFonts.lato(fontSize: 15)),
                          const Spacer(),
                          Switch(
                            value: _repeat,
                            activeThumbColor: Colors.white,
                            activeTrackColor: TimetableScreen._green,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFC7C8CD),
                            onChanged: (value) =>
                                setState(() => _repeat = value),
                          ),
                        ],
                      ),
                      SizedBox(height: keyboardOpen ? 10 : 24),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _days.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final day = _days[index];
                            return _ChoiceChip(
                              label: day,
                              selected: _selectedDays.contains(day),
                              paleWhenUnselected: true,
                              outlineWhenSelected: true,
                              onTap: () => setState(() {
                                if (_selectedDays.contains(day)) {
                                  if (_selectedDays.length > 1) {
                                    _selectedDays.remove(day);
                                  }
                                } else {
                                  _selectedDays.add(day);
                                }
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                    SizedBox(height: keyboardOpen ? 14 : 34),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TimeField(
                          label: 'Starts',
                          value: _timeText(_start),
                          onTap: () => _pickTime(start: true),
                        ),
                        const SizedBox(width: 28),
                        _TimeField(
                          label: 'Ends',
                          value: _timeText(_end),
                          onTap: () => _pickTime(start: false),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (_hasConflict)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFE5E5E5)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'This date and time is already in your timetable',
                                    style: GoogleFonts.lato(fontSize: 13),
                                  ),
                                  const SizedBox(height: 5),
                                  InkWell(
                                    onTap: () => setState(() {
                                      _hasConflict = false;
                                      _type = _EntryType.upcoming;
                                    }),
                                    child: Text(
                                      'Choose another date',
                                      style: GoogleFonts.lato(
                                        color: TimetableScreen._green,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.outlined(
                              onPressed: () =>
                                  setState(() => _hasConflict = false),
                              icon: const Icon(Icons.close, size: 17),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ChoiceChip(
                            label: 'Regular',
                            selected: _type == _EntryType.regular,
                            enabled: !widget.upcomingOnly,
                            onTap: () => setState(() {
                              _type = _EntryType.regular;
                              _hasConflict = false;
                            }),
                          ),
                          const SizedBox(width: 12),
                          _ChoiceChip(
                            label: 'Upcoming',
                            selected: _type == _EntryType.upcoming,
                            onTap: () => setState(() {
                              _type = _EntryType.upcoming;
                              _hasConflict = false;
                            }),
                          ),
                        ],
                      ),
                    SizedBox(height: keyboardOpen ? 12 : 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: canSubmit ? _submit : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: TimetableScreen._green,
                          disabledBackgroundColor: const Color(0xFFB2B2B2),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          widget.subjectMode
                              ? 'Add subject'
                              : 'Add to timetable',
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
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.paleWhenUnselected = false,
    this.outlineWhenSelected = false,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool paleWhenUnselected;
  final bool outlineWhenSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Material(
    color: !enabled
        ? const Color(0xFFB2B2B2)
        : selected && !outlineWhenSelected
        ? TimetableScreen._green
        : paleWhenUnselected
        ? const Color(0xFFF4F9F6)
        : Colors.white,
    shape: StadiumBorder(
      side: selected && outlineWhenSelected
          ? const BorderSide(color: TimetableScreen._green, width: 2)
          : selected || paleWhenUnselected
          ? BorderSide.none
          : const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    child: InkWell(
      onTap: enabled ? onTap : null,
      customBorder: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Text(
          label,
          style: GoogleFonts.lato(
            color: !enabled
                ? Colors.white
                : selected && !outlineWhenSelected
                ? Colors.white
                : TimetableScreen._green,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: GoogleFonts.lato(fontSize: 15)),
      const SizedBox(width: 10),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F9F5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: GoogleFonts.lato(
              color: TimetableScreen._green,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );
}

class _TimetableNavigation extends StatelessWidget {
  const _TimetableNavigation({required this.onTap});

  final ValueChanged<int> onTap;

  static const _items = [
    ('assets/HomeIcon.png', 'Home'),
    ('assets/experienceIconUpdated.png', 'Experiences'),
    ('assets/calenderIconselected.png', 'Timetable'),
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
