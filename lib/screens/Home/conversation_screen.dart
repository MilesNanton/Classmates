import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/message_widget.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.connectionId,
    required this.connectionName,
  });

  final String connectionId;
  final String connectionName;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  static const _green = Color(0xFF0DA64A);
  final _controller = TextEditingController();
  bool _sending = false;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  String? get _threadId {
    if (_userId == null) return null;
    final ids = [_userId!, widget.connectionId]..sort();
    return '${ids.first}_${ids.last}';
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final userId = _userId;
    final threadId = _threadId;
    final text = _controller.text.trim();
    if (userId == null || threadId == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final thread = FirebaseFirestore.instance
          .collection('conversations')
          .doc(threadId);
      final existing = await thread.get();
      final batch = FirebaseFirestore.instance.batch();
      if (existing.exists) {
        batch.update(thread, {
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.set(thread, {
          'participants': [userId, widget.connectionId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }
      batch.set(thread.collection('messages').doc(), {
        'senderId': userId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      _controller.clear();
    } catch (_) {
      if (mounted) {
        showMessagePopup(
          context,
          message: 'Could not send your message.',
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
              _ChatHeader(
                name: widget.connectionName,
                onBack: () => Navigator.maybePop(context),
              ),
              const Divider(height: 1, color: Color(0xFFEAEAEA)),
              Expanded(child: _messages()),
              _composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messages() {
    if (_threadId == null) return const _SafetyCopy();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(_threadId)
          .snapshots(),
      builder: (context, threadSnapshot) {
        if (!threadSnapshot.hasData || !threadSnapshot.data!.exists) {
          return const _SafetyCopy();
        }
        return _messageStream();
      },
    );
  }

  Widget _messageStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(_threadId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const _SafetyCopy();
        }
        final messages = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index].data();
            final createdAt = message['createdAt'];
            final previousCreatedAt = index > 0
                ? messages[index - 1].data()['createdAt']
                : null;
            final showDate =
                index == 0 ||
                !_isSameDay(_dateOf(createdAt), _dateOf(previousCreatedAt));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDate)
                  Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : 14,
                      bottom: 10,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        _dateLabel(createdAt),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          color: const Color(0xFF8A8A8A),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                _ChatBubble(
                  text: message['text'] is String
                      ? message['text'] as String
                      : '',
                  mine: message['senderId'] == _userId,
                  createdAt: createdAt,
                ),
              ],
            );
          },
        );
      },
    );
  }

  static DateTime? _dateOf(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }

  static bool _isSameDay(DateTime? first, DateTime? second) {
    if (first == null || second == null) return false;
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static String _dateLabel(Object? value) {
    final date = _dateOf(value) ?? DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(messageDay).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _composer() {
    final enabled = _controller.text.trim().isNotEmpty && !_sending;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => enabled ? _send() : null,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: enabled ? _green : const Color(0xFFBDBDBD),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: enabled ? _send : null,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(Icons.send_outlined, color: Colors.white, size: 19),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.name, required this.onBack});
  final String name;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
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
                  vertical: 18,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left, size: 22),
                    Text('Back', style: GoogleFonts.lato(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          Text(
            'Message $name',
            style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SafetyCopy extends StatelessWidget {
  const _SafetyCopy();

  @override
  Widget build(BuildContext context) {
    final copy = Text(
      'Keep conversations respectful, protect your personal information and '
      'never share your child’s personal details or other sensitive information.',
      textAlign: TextAlign.center,
      style: GoogleFonts.lato(
        color: const Color(0xFF9A9A9A),
        fontSize: 13,
        height: 1.35,
      ),
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 42),
        child: copy,
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.mine, this.createdAt});
  final String text;
  final bool mine;
  final Object? createdAt;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: mine
                      ? const Color(0xFFEAF8EF)
                      : const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(text, style: GoogleFonts.lato(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _formatTime(createdAt),
              style: GoogleFonts.lato(
                color: const Color(0xFF8A8A8A),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(Object? value) {
    if (value is! Timestamp) return '';
    final date = value.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')}${date.hour >= 12 ? 'pm' : 'am'}';
  }
}
