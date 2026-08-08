import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'message_widget.dart';

Future<void> showReportPostPopup(BuildContext context, {String? postId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => _ReportPostPopup(postId: postId),
  );
}

Future<void> showReplyPostPopup(
  BuildContext context, {
  required String authorName,
  required String postContent,
  String? postId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => _ReplyPostPopup(
      authorName: authorName,
      postContent: postContent,
      postId: postId,
    ),
  );
}

class _ReportPostPopup extends StatefulWidget {
  const _ReportPostPopup({this.postId});

  final String? postId;

  @override
  State<_ReportPostPopup> createState() => _ReportPostPopupState();
}

class _ReportPostPopupState extends State<_ReportPostPopup> {
  bool _confirming = false;
  bool _sending = false;

  Future<void> _report() async {
    if (!_confirming) {
      setState(() => _confirming = true);
      return;
    }

    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('postReports').add({
        'postId': widget.postId,
        'reportedBy': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Keep the demo flow usable when Firestore permissions are not configured.
    }
    if (!mounted) return;
    showMessagePopup(context, message: 'Post reported for review');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (_confirming) ...[
                      _ConfirmPill(
                        label: 'Are you sure?',
                        color: const Color(0xFFFFE9EC),
                        textColor: const Color(0xFFE64653),
                      ),
                      const Spacer(),
                      _ConfirmPill(
                        label: 'No',
                        onTap: () => setState(() => _confirming = false),
                      ),
                      const SizedBox(width: 12),
                      _ConfirmPill(
                        label: 'Yes',
                        color: const Color(0xFFFFE9EC),
                        textColor: const Color(0xFFE64653),
                        onTap: _sending ? null : _report,
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    _CloseButton(onTap: () => Navigator.of(context).pop()),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Something not right?',
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "If you think this post is inappropriate, misleading, or doesn't "
                  'follow our Community Guidelines, you can report it for review.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    height: 1.45,
                    color: const Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 51,
                  child: FilledButton(
                    onPressed: _sending ? null : _report,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA9B1),
                      foregroundColor: const Color(0xFFB00013),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Report post',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyPostPopup extends StatefulWidget {
  const _ReplyPostPopup({
    required this.authorName,
    required this.postContent,
    this.postId,
  });

  final String authorName;
  final String postContent;
  final String? postId;

  @override
  State<_ReplyPostPopup> createState() => _ReplyPostPopupState();
}

class _ReplyPostPopupState extends State<_ReplyPostPopup> {
  final _controller = TextEditingController();
  final _replyFocusNode = FocusNode();
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    final handle = widget.authorName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    _controller.text = '@$handle ';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final replyText = _controller.text
        .trim()
        .replaceFirst(RegExp(r'^@\S+\s*'), '')
        .trim();
    if (replyText.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final postId = widget.postId;
      if (postId != null) {
        final post = FirebaseFirestore.instance.collection('posts').doc(postId);
        await post.collection('replies').add({
          'content': replyText,
          'authorId': FirebaseAuth.instance.currentUser?.uid,
          'authorName': _replyAuthorName(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        await post.update({'replyCount': FieldValue.increment(1)});
      }
    } catch (_) {
      // Dummy posts still support the complete local interaction flow.
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  String _replyAuthorName() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Community member';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: _CloseButton(onTap: () => Navigator.of(context).pop()),
                ),
                if (_sent) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Message sent',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 46),
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0DA64A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.lato(fontSize: 12),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 1,
                    height: 1,
                    child: Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _controller,
                        focusNode: _replyFocusNode,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Reply to ${widget.authorName}',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.postContent,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        color: const Color(0xFF4A4A4A),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    focusNode: _replyFocusNode,
                    autofocus: true,
                    minLines: 1,
                    maxLines: 3,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF333333),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF7F7F7),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: FilledButton(
                      onPressed: _sending ? null : _send,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0DA64A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        _sending ? 'Sending...' : 'Send message',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: const Icon(Icons.close, size: 17),
      ),
    );
  }
}

class _ConfirmPill extends StatelessWidget {
  const _ConfirmPill({
    required this.label,
    this.color = const Color(0xFFE9E9E9),
    this.textColor = const Color(0xFF777777),
    this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
