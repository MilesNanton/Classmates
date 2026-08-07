// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/community_settings_popup.dart';
import '../../widgets/home_pop_up.dart';
import '../../widgets/home_post_popup.dart';
import '../../widgets/post_interaction_popup.dart';

class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key, this.showGuidelines = false});

  final bool showGuidelines;

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  static const _green = Color(0xFF0DA64A);

  bool _showReplies = false;
  int _bottomIndex = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.showGuidelines) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        barrierLabel: 'Community guidelines',
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => const HomeGuidelinesPopup(),
        transitionBuilder: (_, animation, _, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      );
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
              Expanded(child: _buildFeed()),
              _buildFeedFilter(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
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
              'Home',
              style: GoogleFonts.lato(
                color: const Color(0xFF171717),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Material(
              color: Colors.white,
              shape: CircleBorder(
                side: BorderSide(color: const Color(0xFFE5E5E5)),
              ),
              child: InkWell(
                onTap: () => showCommunitySettingsPopup(context),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Icon(Icons.tune_rounded, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: _green,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => showHomePostPopup(context),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Image(
                      image: AssetImage('assets/postIcon.png'),
                      width: 17,
                      height: 17,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const _NoMatchingCommunity();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, profileSnapshot) {
        if (!profileSnapshot.hasData && !profileSnapshot.hasError) {
          return const Center(
            child: CircularProgressIndicator(color: _green, strokeWidth: 2),
          );
        }

        final preferences = profileSnapshot.data?.data() ?? const {};
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('posts').snapshots(),
          builder: (context, postsSnapshot) {
            if (postsSnapshot.hasError) {
              return _showReplies
                  ? const _EmptyReplies()
                  : const _NoMatchingCommunity();
            }

            if (!postsSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _green, strokeWidth: 2),
              );
            }

            final posts = postsSnapshot.data!.docs.toList()
              ..sort(
                (a, b) => _postDate(b.data()).compareTo(_postDate(a.data())),
              );
            if (_showReplies) {
              final replyPosts = posts.where(_isReplyForCurrentUser).toList();
              return replyPosts.isEmpty
                  ? const _EmptyReplies()
                  : _buildReplyThreads(replyPosts);
            }

            final visiblePosts = posts
                .where(
                  (post) =>
                      _matchesCommunity(post.data(), preferences, user.uid),
                )
                .toList();

            if (visiblePosts.isEmpty) {
              return const _NoMatchingCommunity();
            }

            return _buildPostList(
              visiblePosts
                  .map(
                    (post) => <String, dynamic>{...post.data(), '_id': post.id},
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildReplyThreads(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> posts,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      itemCount: posts.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 28, color: Color(0xFFE4E4E4)),
      itemBuilder: (context, index) =>
          _ReplyThread(post: posts[index].data(), postId: posts[index].id),
    );
  }

  static bool _matchesCommunity(
    Map<String, dynamic> post,
    Map<String, dynamic> preferences,
    String? currentUserId,
  ) {
    if (currentUserId != null && post['authorId'] == currentUserId) return true;

    final approach = preferences['homeschoolApproach'];
    final subjects = _stringList(preferences['subjects']).toSet();
    if ((approach == null || approach == '') && subjects.isEmpty) return true;

    final sameApproach =
        approach is String &&
        approach.isNotEmpty &&
        post['homeschoolApproach'] == approach;
    final postSubjects = _stringList(post['subjects']);
    final sharedSubject = postSubjects.any(subjects.contains);

    final usesLocation = preferences['locationSharingEnabled'] == true;
    final inDiscoveryRegion = !usesLocation || post['communityRegion'] == 'UK';
    return inDiscoveryRegion && (sameApproach || sharedSubject);
  }

  Widget _buildPostList(List<Map<String, dynamic>> posts) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (context, index) => _PostCard(post: posts[index]),
    );
  }

  static DateTime _postDate(Map<String, dynamic> post) {
    final value = post['createdAt'];
    return value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _isReplyForCurrentUser(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final post = document.data();
    final replyUsers = _stringList(post['replyToUserIds']);
    final mentionedUsers = _stringList(post['mentionedUserIds']);
    final replyCount = post['replyCount'] is num
        ? (post['replyCount'] as num).toInt()
        : 0;

    return replyUsers.contains(userId) ||
        mentionedUsers.contains(userId) ||
        (post['authorId'] == userId && replyCount > 0);
  }

  static List<String> _stringList(Object? value) {
    return value is Iterable ? value.whereType<String>().toList() : const [];
  }

  Widget _buildFeedFilter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FilterChip(
            label: 'All',
            selected: !_showReplies,
            onTap: () => setState(() => _showReplies = false),
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'Replies',
            selected: _showReplies,
            onTap: () => setState(() => _showReplies = true),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.waving_hand_outlined, 'Experiences'),
      (Icons.business_center_outlined, 'Resources'),
      (Icons.person_outline_rounded, 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
        ),
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == _bottomIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _bottomIndex = index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (index == 0)
                        const Image(
                          image: AssetImage('assets/HomeIcon.png'),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        )
                      else if (index == 1)
                        const Image(
                          image: AssetImage('assets/ExperienceIcon.png'),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        )
                      else if (index == 2)
                        const Image(
                          image: AssetImage('assets/resorcessIcon.png'),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        )
                      else if (index == 3)
                        const Image(
                          image: AssetImage('assets/profileIcon.png'),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        )
                      else
                        Icon(
                          item.$1,
                          size: 20,
                          color: selected
                              ? const Color(0xFF111111)
                              : const Color(0xFF4B4B4B),
                        ),
                      const SizedBox(height: 3),
                      Text(
                        item.$2,
                        style: GoogleFonts.lato(
                          color: const Color(0xFF111111),
                          fontSize: 11,
                          fontWeight: selected
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
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
          color: selected ? const Color(0xFF0DA64A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF0DA64A) : const Color(0xFFD9D9D9),
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

class _EmptyReplies extends StatelessWidget {
  const _EmptyReplies();

  @override
  Widget build(BuildContext context) {
    return const _FeedMessage(
      icon: Icons.mark_chat_unread_outlined,
      title: 'No replies yet',
      description:
          'Replies to your posts and mentions\nfrom other parents will appear here.',
      actionText:
          'Join the conversation by asking a\nquestion or replying to a post.',
    );
  }
}

class _NoMatchingCommunity extends StatelessWidget {
  const _NoMatchingCommunity();

  @override
  Widget build(BuildContext context) {
    return const _FeedMessage(
      icon: Icons.groups_outlined,
      title: 'Your community is growing',
      description:
          'Posts matching your homeschool style, subjects,\nand location will appear here.',
      actionText:
          'Update Community settings anytime to\ndiscover more conversations.',
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFFA3A3A3), size: 24),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFFA3A3A3),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.emoji_people_outlined,
                  color: Color(0xFFA3A3A3),
                  size: 25,
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFFA3A3A3),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: const Color(0xFF171717),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: const Color(0xFF333333),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (actionText case final text?) ...[
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  color: const Color(0xFF0DA64A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplyThread extends StatelessWidget {
  const _ReplyThread({required this.post, required this.postId});

  final Map<String, dynamic> post;
  final String postId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('replies')
          .snapshots(),
      builder: (context, snapshot) {
        final liveReplies = <Map<String, dynamic>>[
          ...?snapshot.data?.docs.map((document) => document.data()),
        ];
        liveReplies.sort((a, b) => _replyDate(a).compareTo(_replyDate(b)));
        return _buildThread(liveReplies);
      },
    );
  }

  Widget _buildThread(List<Map<String, dynamic>> threadReplies) {
    final original = _firstText(post, ['content', 'text', 'body']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFF6F6F6),
          child: Text(
            original,
            style: GoogleFonts.lato(
              color: const Color(0xFF9A9A9A),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (threadReplies.isEmpty)
          Text(
            'Waiting for replies...',
            style: GoogleFonts.lato(
              color: const Color(0xFF8A8A8A),
              fontSize: 14,
            ),
          )
        else
          ...threadReplies.map(_buildReply),
      ],
    );
  }

  Widget _buildReply(Map<String, dynamic> reply) {
    final author = _firstText(reply, ['authorName', 'userName', 'name']);
    final body = _firstText(reply, [
      'content',
      'text',
      'body',
    ]).replaceFirst(RegExp(r'^@\S+\s*'), '').trim();
    final initials = author
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: const Color(0xFFEAF4FF),
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: GoogleFonts.lato(
                    color: const Color(0xFF3478C9),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.isEmpty ? 'Community member' : author,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF282828),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _timeAgo(reply['createdAt']),
                    style: GoogleFonts.lato(
                      color: const Color(0xFF8A8A8A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            body,
            style: GoogleFonts.lato(
              color: const Color(0xFF333333),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _replyDate(Map<String, dynamic> reply) {
    final value = reply['createdAt'];
    return value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _timeAgo(Object? value) {
    final date = value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : null;
    if (date == null) return 'Just now';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays}d ago';
  }

  static String _firstText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final author = _firstText(post, ['authorName', 'userName', 'name']);
    final body = _firstText(post, ['content', 'text', 'body']);
    final initials = author
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    final postContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFEAF4FF),
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: GoogleFonts.lato(
                  color: const Color(0xFF3478C9),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.isEmpty ? 'Community member' : author,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF333333),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _timeAgo(post['createdAt']),
                    style: GoogleFonts.lato(
                      color: const Color(0xFF8A8A8A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text(
            body,
            style: GoogleFonts.lato(
              color: const Color(0xFF444444),
              fontSize: 16,
              height: 1.42,
            ),
          ),
        ],
      ],
    );

    return _SwipeablePost(
      onReport: () =>
          showReportPostPopup(context, postId: post['_id'] as String?),
      onReply: () => showReplyPostPopup(
        context,
        authorName: author.isEmpty ? 'Community member' : author,
        postContent: body,
        postId: post['_id'] as String?,
      ),
      child: postContent,
    );
  }

  static String _timeAgo(Object? value) {
    final date = value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : null;
    if (date == null) return 'Just now';

    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    }
    return '${difference.inDays}d ago';
  }

  static String _firstText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}

class _SwipeablePost extends StatefulWidget {
  const _SwipeablePost({
    required this.child,
    required this.onReport,
    required this.onReply,
  });

  final Widget child;
  final VoidCallback onReport;
  final VoidCallback onReply;

  @override
  State<_SwipeablePost> createState() => _SwipeablePostState();
}

class _SwipeablePostState extends State<_SwipeablePost> {
  static const double _actionsWidth = 96;
  double _offset = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(-_actionsWidth, 0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final open =
        _offset.abs() > _actionsWidth / 3 ||
        details.primaryVelocity != null && details.primaryVelocity! < -250;
    setState(() => _offset = open ? -_actionsWidth : 0);
  }

  void _runAction(VoidCallback action) {
    setState(() => _offset = 0);
    action();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          SizedBox(
            width: _actionsWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SwipeAction(
                  icon: Icons.report_gmailerrorred_outlined,
                  label: 'Report',
                  onTap: () => _runAction(widget.onReport),
                ),
                _SwipeAction(
                  icon: Icons.reply_rounded,
                  label: 'Reply',
                  onTap: () => _runAction(widget.onReply),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_offset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onTap: _offset == 0 ? null : () => setState(() => _offset = 0),
              child: ColoredBox(
                color: Colors.white,
                child: SizedBox(width: double.infinity, child: widget.child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFDADADA)),
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF222222)),
        ),
      ),
    );
  }
}
