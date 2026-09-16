import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/message_widget.dart';
import '../onbarding/home_screen.dart';

Future<bool> hasSubscriptionAccess() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  try {
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return profile.data()?['subscriptionActive'] == true;
  } on FirebaseException {
    return false;
  }
}

Future<void> runWithSubscriptionAccess(
  BuildContext context,
  Future<void> Function() onGranted,
) async {
  if (await hasSubscriptionAccess()) {
    await onGranted();
    return;
  }
  if (context.mounted) await showSubscriptionPaywall(context);
}

Future<void> showSubscriptionPaywall(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black45,
    builder: (_) => const _SubscriptionSheet(),
  );
}

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  static const _green = Color(0xFF079B43);
  static const _sectionBackground = Color(0xFFF4FBF7);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: _sectionBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _Header(onBack: () => Navigator.maybePop(context)),
              const Expanded(child: _SettingsList()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
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
                    const SizedBox(width: 2),
                    Text('Back', style: GoogleFonts.lato(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          Text(
            'Settings',
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF222222),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _SectionTitle('Safety first'),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/best_practices.png',
          label: 'Best practices',
          onTap: () => _showBestPractices(context),
        ),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/community_guidline.png',
          label: 'Community guidelines',
          onTap: () => _showCommunityGuidelines(context),
        ),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/meetup_safety.png',
          label: 'Meetup safety',
          onTap: () => _showMeetupSafety(context),
        ),
        const _SectionTitle('Share'),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/invite_others.png',
          label: 'Invite others',
          onTap: () => _inviteOthers(context),
        ),
        const _SectionTitle('Account'),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/change_password.png',
          label: 'Change password',
          onTap: () => _showChangePassword(context),
        ),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/restore_purchases.png',
          label: 'Restore purchases',
          onTap: () => _showUnavailable(context, 'Restore purchases'),
        ),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/manage_subscription.png',
          label: 'Manage subscription',
          onTap: () => _showManageSubscription(context),
        ),
        const _SectionTitle('Danger'),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/delete.png',
          label: 'Delete account',
          onTap: () => _confirmDeleteAccount(context),
        ),
        const _SectionTitle('Help'),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/terms_conditions.png',
          label: 'Terms and Conditions',
          onTap: () =>
              _openWebPage(context, 'https://www.theclassmatesapp.com/terms'),
        ),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/privacy_policy.png',
          label: 'Privacy policy',
          onTap: () =>
              _openWebPage(context, 'https://www.theclassmatesapp.com/privacy'),
        ),
        const _Footer(),
      ],
    );
  }

  static void _showUnavailable(BuildContext context, String feature) {
    showMessagePopup(context, message: '$feature coming soon');
  }

  static Future<void> _showChangePassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showMessagePopup(
        context,
        message: 'Please sign in again to change your password.',
        type: MessageType.error,
      );
      return;
    }

    final usesPassword = user.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    );
    if (!usesPassword || user.email == null) {
      showMessagePopup(
        context,
        message:
            'Password changes are only available for email and password accounts.',
        type: MessageType.error,
      );
      return;
    }

    final passwordChanged = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(user: user),
    );
    if (passwordChanged == true && context.mounted) {
      await _showPasswordChanged(context);
    }
  }

  static Future<void> _confirmDeleteAccount(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account and profile data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete account',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _openGetStarted(context);
      return;
    }

    // Firebase only permits account deletion shortly after authentication.
    // Check this before deleting Firestore data so a failed auth deletion does
    // not leave the user with an account but no profile.
    final lastSignIn = user.metadata.lastSignInTime;
    if (lastSignIn == null ||
        DateTime.now().difference(lastSignIn) > const Duration(minutes: 4)) {
      showMessagePopup(
        context,
        message:
            'Please log out and sign in again before deleting your account.',
        type: MessageType.error,
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final profile = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await _deleteProfileData(profile);
      await user.delete();

      if (!context.mounted) return;
      Navigator.of(context).pop();
      _openGetStarted(context);
      showMessagePopupInOverlay(
        overlay,
        message: 'Account deleted successfully.',
      );
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showMessagePopup(
        context,
        message: error.code == 'requires-recent-login'
            ? 'Please log out and sign in again before deleting your account.'
            : 'Unable to delete your account. Please try again.',
        type: MessageType.error,
      );
    } on FirebaseException {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showMessagePopup(
        context,
        message: 'Unable to delete your account. Please try again.',
        type: MessageType.error,
      );
    }
  }

  static Future<void> _deleteProfileData(
    DocumentReference<Map<String, dynamic>> profile,
  ) async {
    for (final collectionName in const [
      'completedExperiences',
      'savedResources',
      'parents',
      'subjectProgress',
      'timetableEntries',
    ]) {
      final documents = await profile.collection(collectionName).get();
      for (var start = 0; start < documents.docs.length; start += 450) {
        final batch = FirebaseFirestore.instance.batch();
        for (final document in documents.docs.skip(start).take(450)) {
          batch.delete(document.reference);
        }
        await batch.commit();
      }
    }
    await profile.delete();
  }

  static void _openGetStarted(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  static Future<void> _openWebPage(BuildContext context, String url) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      showMessagePopup(
        context,
        message: 'Unable to open this page. Please try again.',
        type: MessageType.error,
      );
    }
  }

  static Future<void> _inviteOthers(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    await SharePlus.instance.share(
      ShareParams(
        text:
            'Join me on Classmates — a place for parents and carers to connect, share experiences and support each other.',
        subject: 'Join me on Classmates',
        sharePositionOrigin: origin,
      ),
    );
  }

  static Future<void> _showBestPractices(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      builder: (_) => const _SafetyGuidanceSheet(
        title: 'Best practices',
        items: _bestPractices,
        heightFactor: 0.76,
      ),
    );
  }

  static Future<void> _showCommunityGuidelines(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      builder: (_) => const _SafetyGuidanceSheet(
        title: 'Community guidelines',
        items: _communityGuidelines,
        heightFactor: 0.80,
      ),
    );
  }

  static Future<void> _showMeetupSafety(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      builder: (_) => const _SafetyGuidanceSheet(
        title: 'Meetup safety',
        items: _meetupSafety,
        heightFactor: 0.76,
      ),
    );
  }

  static Future<void> _showManageSubscription(BuildContext context) {
    return showSubscriptionPaywall(context);
  }

  static const _bestPractices = <(String, String)>[
    (
      'Keep your information private',
      'Avoid sharing your home address, phone number, personal contact details or other sensitive information.',
    ),
    (
      'Protect your child’s privacy',
      'Never share your child’s full name, school, location or other identifying details with people you don’t know well.',
    ),
    (
      'Connect with people you meet',
      'Only add connections you’ve met through a Classmates event or trusted community setting.',
    ),
    (
      'Keep conversations respectful',
      'Be kind, respectful and considerate when messaging or interacting with other parents and carers.',
    ),
    (
      'Meet safely',
      'When meeting a connection outside of a Classmates event, choose a public place and let someone you trust know where you’re going.',
    ),
    (
      'Trust your instincts',
      'If something doesn’t feel right, you can stop communicating, remove the connection or report the user to Classmates.',
    ),
  ];

  static const _communityGuidelines = <(String, String)>[
    (
      'Be respectful',
      'Treat other parents and carers with kindness, even when you have different views or experiences.',
    ),
    (
      'Keep it helpful',
      'Share useful experiences, ask genuine questions and offer advice that could support the community.',
    ),
    (
      'Protect privacy',
      'Don’t share someone else’s personal information, photos or details without their permission.',
    ),
    (
      'Keep children’s information private',
      'Avoid posting children’s full names, school details, locations or other identifying information.',
    ),
    (
      'No harassment or bullying',
      'Don’t threaten, intimidate, shame or repeatedly target other members.',
    ),
    (
      'Keep content appropriate',
      'Don’t post offensive, harmful, discriminatory or inappropriate content.',
    ),
    (
      'Respect the community',
      'Avoid spam, advertising, misleading information or content that doesn’t belong on Classmates.',
    ),
    (
      'Report concerns',
      'If you see something that goes against these guidelines, report it so we can help keep Classmates welcoming and safe.',
    ),
  ];

  static const _meetupSafety = <(String, String)>[
    (
      'Meet in public places',
      'Choose a familiar, public location for your first meetup and avoid sharing your home address.',
    ),
    (
      'Tell someone you trust',
      'Let a friend or family member know where you’re going, who you’re meeting and when you expect to be back.',
    ),
    (
      'Keep personal details private',
      'Only share information you’re comfortable with. Never share your child’s school, address or other sensitive details.',
    ),
    (
      'Meet on your terms',
      'You’re never under any obligation to meet someone. If something doesn’t feel right, leave or cancel the meetup.',
    ),
    (
      'Keep children safe',
      'Stay responsible for your own children and follow the safety guidance of the venue or activity you’re attending.',
    ),
    (
      'Trust your instincts',
      'If someone makes you feel uncomfortable or behaves inappropriately, stop communicating and report them to Classmates.',
    ),
  ];
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.user});

  final User user;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  static const _green = Color(0xFF08A948);

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  bool _isSendingReset = false;
  bool _currentPasswordHasError = false;
  bool _newPasswordHasError = false;
  bool _confirmPasswordHasError = false;

  bool get _canSubmit {
    return !_isChangingPassword &&
        !_isSendingReset &&
        _currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_refresh);
    _newPasswordController.addListener(_refresh);
    _confirmPasswordController.addListener(_refresh);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _currentPasswordHasError = false;
      _newPasswordHasError = false;
      _confirmPasswordHasError = false;
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final email = widget.user.email;
    if (!_canSubmit || email == null) return;

    final newPassword = _newPasswordController.text;
    if (newPassword.length < 6) {
      setState(() {
        _newPasswordHasError = true;
        _confirmPasswordHasError = true;
      });
      showMessagePopup(
        context,
        message: 'Password must contain at least 6 characters',
        type: MessageType.error,
      );
      return;
    }
    if (_confirmPasswordController.text != newPassword) {
      setState(() {
        _newPasswordHasError = true;
        _confirmPasswordHasError = true;
      });
      showMessagePopup(
        context,
        message: "Passwords don't match",
        type: MessageType.error,
      );
      return;
    }
    if (newPassword == _currentPasswordController.text) {
      setState(() {
        _newPasswordHasError = true;
        _confirmPasswordHasError = true;
      });
      showMessagePopup(
        context,
        message: 'Your new password must be different',
        type: MessageType.error,
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _currentPasswordHasError = false;
      _newPasswordHasError = false;
      _confirmPasswordHasError = false;
    });

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text,
      );
      await widget.user.reauthenticateWithCredential(credential);
      await widget.user.updatePassword(newPassword);

      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final isCurrentPasswordError =
          error.code == 'wrong-password' || error.code == 'invalid-credential';
      setState(() {
        _isChangingPassword = false;
        _currentPasswordHasError = isCurrentPasswordError;
        _newPasswordHasError = error.code == 'weak-password';
        _confirmPasswordHasError = error.code == 'weak-password';
      });
      showMessagePopup(
        context,
        message: switch (error.code) {
          'wrong-password' ||
          'invalid-credential' => 'Current password is incorrect',
          'weak-password' => 'Please choose a stronger password',
          'too-many-requests' => 'Too many attempts. Please wait and try again',
          'network-request-failed' =>
            'Please check your internet connection and try again',
          _ => 'Unable to change your password. Please try again',
        },
        type: MessageType.error,
      );
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = widget.user.email;
    if (email == null || _isSendingReset) return;

    setState(() {
      _isSendingReset = true;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      final overlay = Overlay.of(context, rootOverlay: true);
      Navigator.pop(context);
      showMessagePopupInOverlay(
        overlay,
        message: 'Password reset email sent to $email.',
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _isSendingReset = false);
      showMessagePopup(
        context,
        message: error.code == 'network-request-failed'
            ? 'Please check your internet connection and try again'
            : 'Unable to send the reset email. Please try again',
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Change password',
                        style: GoogleFonts.lato(
                          color: const Color(0xFF181818),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(
                        side: BorderSide(color: Color(0xFFE2E2E2)),
                      ),
                      child: InkWell(
                        onTap: _isChangingPassword || _isSendingReset
                            ? null
                            : () => Navigator.pop(context),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(Icons.close, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _PasswordField(
                  controller: _currentPasswordController,
                  hintText: 'Current password',
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                  hasError: _currentPasswordHasError,
                ),
                const SizedBox(height: 12),
                _PasswordField(
                  controller: _newPasswordController,
                  hintText: 'New password',
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  hasError: _newPasswordHasError,
                ),
                const SizedBox(height: 12),
                _PasswordField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm new password',
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _changePassword(),
                  hasError: _confirmPasswordHasError,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 46,
                  child: FilledButton(
                    onPressed: _canSubmit ? _changePassword : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor: const Color(0xFFB7B7B7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: _isChangingPassword
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Change password',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isChangingPassword || _isSendingReset
                      ? null
                      : _sendPasswordReset,
                  child: _isSendingReset
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _green,
                          ),
                        )
                      : Text(
                          'Forgot password?',
                          style: GoogleFonts.lato(
                            color: _green,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hintText,
    required this.autofillHints,
    required this.textInputAction,
    this.hasError = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final Iterable<String> autofillHints;
  final TextInputAction textInputAction;
  final bool hasError;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF181818)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.lato(
          fontSize: 13,
          color: const Color(0xFF8C8C8C),
        ),
        filled: true,
        fillColor: const Color(0xFFF4F4F6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: hasError
              ? const BorderSide(color: Color(0xFFFF3B4E))
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: hasError
              ? const BorderSide(color: Color(0xFFFF3B4E))
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(
            color: hasError
                ? const Color(0xFFFF3B4E)
                : _ChangePasswordSheetState._green,
          ),
        ),
      ),
    );
  }
}

Future<void> _showPasswordChanged(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black45,
    builder: (sheetContext) => Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Password changed',
                      style: GoogleFonts.lato(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181818),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(
                      side: BorderSide(color: Color(0xFFE2E2E2)),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.pop(sheetContext),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(Icons.close, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 52),
              SizedBox(
                height: 46,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ChangePasswordSheetState._green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.lato(
                      fontSize: 14,
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
  );
}

class _SafetyGuidanceSheet extends StatelessWidget {
  const _SafetyGuidanceSheet({
    required this.title,
    required this.items,
    required this.heightFactor,
  });

  final String title;
  final List<(String, String)> items;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        color: const Color(0xFF181818),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(
                        side: BorderSide(color: Color(0xFFE2E2E2)),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(Icons.close, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 22),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: GoogleFonts.lato(
                          color: const Color(0xFF181818),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.$2,
                        style: GoogleFonts.lato(
                          color: const Color(0xFF222222),
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 14, 30, 28),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF08A948),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: Text(
                    'I understand',
                    style: GoogleFonts.lato(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
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
}

class _SubscriptionSheet extends StatefulWidget {
  const _SubscriptionSheet();

  @override
  State<_SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends State<_SubscriptionSheet> {
  static const _features = <({String title, String description})>[
    (
      title: 'Discover learning experiences',
      description:
          'Find interesting places, activities and outings designed with homeschooling families in mind.',
    ),
    (
      title: 'Build your child’s learning pathway',
      description:
          'Follow structured subject pathways or choose a flexible route that fits your child.',
    ),
    (
      title: 'Plan your week',
      description:
          'Organise subjects, activities, clubs and regular routines in one place.',
    ),
    (
      title: 'Connect with homeschooling families',
      description:
          'Meet parents and carers, share ideas and message your connections directly.',
    ),
    (
      title: 'Document your homeschooling journey',
      description:
          'Save experiences, add notes and photos, and keep a record of what your child has done.',
    ),
  ];

  bool _yearly = false;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.95,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 154,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: const Color(0xFFC9F4C6),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: double.infinity,
                        height: 150,
                        child: Image.asset(
                          'assets/screensIcons/ExprienceIcon.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 16,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(Icons.close, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Subscribe to Classmates',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  color: const Color(0xFF181818),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _PlanCard(
                      price: '£4.99',
                      period: 'per month',
                      selected: !_yearly,
                      onTap: () => setState(() => _yearly = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PlanCard(
                      price: '£49.99',
                      period: 'per year',
                      badge: '16% off',
                      selected: _yearly,
                      onTap: () => setState(() => _yearly = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    for (final feature in _features)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.check, size: 18),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    feature.title,
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    feature.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.lato(
                                      color: const Color(0xFF333333),
                                      fontSize: 11.5,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: FilledButton(
                  onPressed: () => showMessagePopup(
                    context,
                    message: 'Subscription checkout coming soon',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF08A948),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    _yearly
                        ? 'Subscribe for £49.99 / year'
                        : 'Subscribe for £4.99 / month',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _yearly
                        ? '£49.99 billed yearly. '
                        : '£4.99 billed monthly. ',
                  ),
                  const TextSpan(
                    text: 'Terms apply',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ],
              ),
              style: GoogleFonts.lato(
                color: const Color(0xFF6D6D6D),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String price;
  final String period;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4FCF7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF08A948) : const Color(0xFFE0E0E0),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price,
                    maxLines: 1,
                    style: GoogleFonts.lato(
                      fontSize: 17,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    period,
                    maxLines: 1,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF777777),
                      fontSize: 13,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F8EA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.lato(
                    color: const Color(0xFF08A948),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: SettingScreen._sectionBackground,
      child: Text(
        title,
        style: GoogleFonts.lato(
          color: SettingScreen._green,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE9E9E9))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  iconAsset,
                  width: 17,
                  height: 17,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.lato(
                color: const Color(0xFF181818),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SettingScreen._sectionBackground,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () => _confirmLogOut(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: SettingScreen._green,
                side: const BorderSide(color: SettingScreen._green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'Log out',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Version 1.0',
            style: GoogleFonts.lato(
              color: const Color(0xFF222222),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogOut(BuildContext context) async {
    final shouldLogOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: SettingScreen._green),
            ),
          ),
        ],
      ),
    );
    if (shouldLogOut != true || !context.mounted) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (_) => false,
      );
      showMessagePopupInOverlay(overlay, message: 'Logged out successfully.');
    } on FirebaseAuthException {
      if (!context.mounted) return;
      showMessagePopup(
        context,
        message: 'Unable to log out. Please try again.',
        type: MessageType.error,
      );
    }
  }
}
