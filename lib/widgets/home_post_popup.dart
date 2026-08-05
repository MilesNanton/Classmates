import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showHomePostPopup(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => const HomePostPopup(),
  );
}

class HomePostPopup extends StatefulWidget {
  const HomePostPopup({super.key});

  @override
  State<HomePostPopup> createState() => _HomePostPopupState();
}

class _HomePostPopupState extends State<HomePostPopup> {
  static const _green = Color(0xFF0DA64A);

  final _messageController = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendPost() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _errorMessage = 'Please log in before sharing a post.');
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final preferences = profile.data() ?? const <String, dynamic>{};

      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': user.uid,
        'authorName': _authorName(user),
        'content': message,
        'createdAt': FieldValue.serverTimestamp(),
        'replyCount': 0,
        'mentionedUserIds': <String>[],
        'replyToUserIds': <String>[],
        'homeschoolApproach': preferences['homeschoolApproach'],
        'subjects': preferences['subjects'] is Iterable
            ? List<String>.from(
                (preferences['subjects'] as Iterable).whereType<String>(),
              )
            : <String>[],
        'locationSharingEnabled': preferences['locationSharingEnabled'] == true,
        'communityRegion': 'UK',
      });

      if (mounted) Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = error.code == 'permission-denied'
            ? 'You do not have permission to share posts yet.'
            : 'Could not share your post. Please try again.';
      });
    }
  }

  static String _authorName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    final email = user.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Community member';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      color: Colors.transparent,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: _isSending
                        ? null
                        : () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                      image: AssetImage('assets/1_icon.png'),
                      width: 27,
                      height: 27,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 24),
                    Image(
                      image: AssetImage('assets/2_icon.png'),
                      width: 27,
                      height: 27,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 24),
                    Image(
                      image: AssetImage('assets/3_icon.png'),
                      width: 27,
                      height: 27,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 24),
                    Image(
                      image: AssetImage('assets/4_icon.png'),
                      width: 27,
                      height: 27,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Share with your community',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF171717),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ask a question or share an experience with fellow\n'
                  'homeschooling parents.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF737373),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _messageController,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() => _errorMessage = null),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: GoogleFonts.nunito(
                      color: const Color(0xFF737373),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_errorMessage case final message?) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: const Color(0xFFB42318),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed:
                        _isSending || _messageController.text.trim().isEmpty
                        ? null
                        : _sendPost,
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFC5C5C5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Send to community',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
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
