// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/community_settings_popup.dart';
import '../../widgets/home_pop_up.dart';
import '../../widgets/home_post_popup.dart';
import '../../widgets/message_widget.dart';
import '../../widgets/post_interaction_popup.dart';
import '../Profile/profile_screen.dart';
import 'conversation_screen.dart';

enum _FeedView { all, replies, connections }

class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key, this.showGuidelines = false});

  final bool showGuidelines;

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  static const _green = Color(0xFF0DA64A);

  _FeedView _feedView = _FeedView.all;
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
    if (_bottomIndex == 3) {
      return ProfileScreen(
        onTabSelected: (index) => setState(() => _bottomIndex = index),
      );
    }
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
                      image: AssetImage('assets/Messageiconfinal.png'),
                      width: 22,
                      height: 22,
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
              return _feedView == _FeedView.replies
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
            if (_feedView == _FeedView.replies) {
              final replyPosts = posts.where(_isReplyForCurrentUser).toList();
              return replyPosts.isEmpty
                  ? const _EmptyReplies()
                  : _buildReplyThreads(replyPosts);
            }

            if (_feedView == _FeedView.connections) {
              return _buildConnectionsList(user.uid);
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

  Widget _buildConnectionsList(String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('parents')
          .snapshots(),
      builder: (context, connectionsSnapshot) {
        if (connectionsSnapshot.hasError) {
          return const _NoConnectionPosts();
        }
        if (!connectionsSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _green, strokeWidth: 2),
          );
        }

        final connections = connectionsSnapshot.data!.docs;
        if (connections.isEmpty) return const _NoConnectionPosts();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          itemCount: connections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final connection = connections[index];
            final data = connection.data();
            final storedName = data['name'];
            final name = storedName is String && storedName.trim().isNotEmpty
                ? storedName.trim()
                : 'Connection';
            return _HomeConnectionTile(
              name: name,
              curriculum: data['curriculum'] is String
                  ? data['curriculum'] as String
                  : 'Custom curriculum',
              onMessage: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ConversationScreen(
                    connectionId: connection.id,
                    connectionName: name,
                  ),
                ),
              ),
            );
          },
        );
      },
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
            selected: _feedView == _FeedView.all,
            onTap: () => setState(() => _feedView = _FeedView.all),
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'Connections',
            selected: _feedView == _FeedView.connections,
            onTap: () => setState(() => _feedView = _FeedView.connections),
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      if (index == 0)
                        Image(
                          image: AssetImage(
                            selected
                                ? 'assets/Home_active.png'
                                : 'assets/HomeIcon.png',
                          ),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          color: selected ? null : const Color(0xFF7A7A7A),
                          colorBlendMode: BlendMode.srcIn,
                        )
                      else if (index == 1)
                        Image(
                          image: AssetImage(
                            selected
                                ? 'assets/Experiences_Active.png'
                                : 'assets/ExperienceIcon.png',
                          ),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          color: selected ? null : const Color(0xFF7A7A7A),
                          colorBlendMode: BlendMode.srcIn,
                        )
                      else if (index == 2)
                        Image(
                          image: AssetImage(
                            selected
                                ? 'assets/Resources_Active.png'
                                : 'assets/resorcessIcon.png',
                          ),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          color: selected ? null : const Color(0xFF7A7A7A),
                          colorBlendMode: BlendMode.srcIn,
                        )
                      else if (index == 3)
                        Image(
                          image: AssetImage(
                            selected
                                ? 'assets/Profile_Active.png'
                                : 'assets/profileIcon.png',
                          ),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          color: selected ? null : const Color(0xFF7A7A7A),
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      const SizedBox(height: 3),
                      Text(
                        item.$2,
                        style: GoogleFonts.lato(
                          color: const Color(0xFF111111),
                          fontSize: 12,
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
      title: 'No replies yet',
      description:
          'Replies to your posts and mentions\nfrom other parents will appear here.',
      actionText:
          'Join the conversation by asking a\nquestion or replying to a post.',
    );
  }
}

class _HomeConnectionTile extends StatelessWidget {
  const _HomeConnectionTile({
    required this.name,
    required this.curriculum,
    required this.onMessage,
  });

  final String name;
  final String curriculum;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return SizedBox(
      height: 62,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEAF4FF),
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: GoogleFonts.lato(
                color: const Color(0xFF3478C9),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.lato(
                    color: const Color(0xFF171717),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  curriculum,
                  style: GoogleFonts.lato(
                    color: const Color(0xFF737373),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: const Color(0xFFBDBDBD),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onMessage,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Image.asset(
                    'assets/Messageiconfinal.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoConnectionPosts extends StatelessWidget {
  const _NoConnectionPosts();

  @override
  Widget build(BuildContext context) {
    return const _FeedMessage(
      title: 'Your connections',
      description:
          'See the parents and carers you’ve connected with and message them directly.',
    );
  }
}

class _NoMatchingCommunity extends StatelessWidget {
  const _NoMatchingCommunity();

  @override
  Widget build(BuildContext context) {
    return _FeedMessage(
      title: 'No community posts yet',
      description:
          'Your community feed will appear here\nas parents start sharing.',
      actionText: 'Ask a question, share an experience,\nor say hello.',
      onActionTap: () => showHomePostPopup(context),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.title,
    required this.description,
    this.actionText,
    this.onActionTap,
  });

  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
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
                color: const Color(0xFF333333),
                fontSize: 16,
                height: 1.35,
              ),
            ),
            if (actionText case final text?) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: onActionTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF0DA64A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
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

  Future<void> _deletePost(BuildContext context) async {
    final postId = post['_id'] as String?;
    if (postId == null) return;
    final overlay = Overlay.of(context, rootOverlay: true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete post?',
          style: GoogleFonts.lato(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This post will be permanently deleted.',
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF444B),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      if (!overlay.mounted) return;
      showMessagePopupInOverlay(overlay, message: 'Post deleted successfully.');
    } on FirebaseException {
      if (!context.mounted) return;
      showMessagePopup(
        context,
        message: 'Could not delete this post.',
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = _firstText(post, ['authorName', 'userName', 'name']);
    final body = _firstText(post, ['content', 'text', 'body']);
    final isOwner = post['authorId'] == FirebaseAuth.instance.currentUser?.uid;
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

    final postId = post['_id'] as String?;
    return _SwipeablePost(
      onReport: () => showReportPostPopup(context, postId: postId),
      onReply: () =>
          showReplyPostPopup(context, postContent: body, postId: postId),
      onDelete: isOwner ? () => _deletePost(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          postContent,
          if (postId != null) _PublicPostReplies(postId: postId),
        ],
      ),
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

class _PublicPostReplies extends StatefulWidget {
  const _PublicPostReplies({required this.postId});

  final String postId;

  @override
  State<_PublicPostReplies> createState() => _PublicPostRepliesState();
}

class _PublicPostRepliesState extends State<_PublicPostReplies> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('replies')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final replies = snapshot.data!.docs.map((doc) => doc.data()).toList()
          ..sort((a, b) => _date(a).compareTo(_date(b)));
        final collapsible = replies.length >= 4;

        if (collapsible && !_expanded) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _RepliesToggle(
              label: 'View ${replies.length} replies',
              onTap: () => setState(() => _expanded = true),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${replies.length} ${replies.length == 1 ? 'Reply' : 'Replies'}',
                style: GoogleFonts.lato(
                  color: const Color(0xFF0DA64A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...replies.map(_reply),
              if (collapsible)
                _RepliesToggle(
                  label: 'Hide replies',
                  onTap: () => setState(() => _expanded = false),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _reply(Map<String, dynamic> reply) {
    final storedName = reply['authorName'];
    final author = storedName is String && storedName.trim().isNotEmpty
        ? storedName.trim()
        : 'Community member';
    final storedContent = reply['content'];
    final content = storedContent is String ? storedContent.trim() : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            author,
            style: GoogleFonts.lato(
              color: const Color(0xFF333333),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _timeAgo(reply['createdAt']),
            style: GoogleFonts.lato(
              color: const Color(0xFF8A8A8A),
              fontSize: 10,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              content,
              style: GoogleFonts.lato(
                color: const Color(0xFF444444),
                fontSize: 14,
                height: 1.42,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static DateTime _date(Map<String, dynamic> reply) {
    final value = reply['createdAt'];
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _timeAgo(Object? value) {
    if (value is! Timestamp) return 'Just now';
    final difference = DateTime.now().difference(value.toDate());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays}d ago';
  }
}

class _RepliesToggle extends StatelessWidget {
  const _RepliesToggle({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: GoogleFonts.lato(
            color: const Color(0xFF0DA64A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SwipeablePost extends StatefulWidget {
  const _SwipeablePost({
    required this.child,
    required this.onReport,
    required this.onReply,
    this.onDelete,
  });

  final Widget child;
  final VoidCallback onReport;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  @override
  State<_SwipeablePost> createState() => _SwipeablePostState();
}

class _SwipeablePostState extends State<_SwipeablePost> {
  double get _actionsWidth => widget.onDelete == null ? 120 : 180;
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
          IgnorePointer(
            ignoring: _offset == 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _offset == 0 ? 0 : 1,
              child: SizedBox(
                width: _actionsWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SwipeAction(
                      icon: Icons.reply_rounded,
                      label: 'Reply',
                      backgroundColor: const Color(0xFF12B76A),
                      foregroundColor: Colors.white,
                      onTap: () => _runAction(widget.onReply),
                    ),
                    _SwipeAction(
                      icon: Icons.error_outline_rounded,
                      label: 'Flag',
                      backgroundColor: const Color(0xFFA9A9A9),
                      foregroundColor: Colors.white,
                      onTap: () => _runAction(widget.onReport),
                    ),
                    if (widget.onDelete case final onDelete?)
                      _SwipeAction(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        backgroundColor: const Color(0xFFFF444B),
                        foregroundColor: Colors.white,
                        onTap: () => _runAction(onDelete),
                      ),
                  ],
                ),
              ),
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
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 54,
          height: 58,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: foregroundColor),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.lato(
                  color: foregroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
