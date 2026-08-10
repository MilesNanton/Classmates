import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/message_widget.dart';

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
          onTap: () => _showUnavailable(context, 'Best practices'),
        ),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/community_guidline.png',
          label: 'Community guidelines',
          onTap: () => _showUnavailable(context, 'Community guidelines'),
        ),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/meetup_safety.png',
          label: 'Meetup safety',
          onTap: () => _showUnavailable(context, 'Meetup safety'),
        ),
        const _SectionTitle('Share'),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/invite_others.png',
          label: 'Invite others',
          onTap: () => _showUnavailable(context, 'Invite others'),
        ),
        const _SectionTitle('Account'),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/change_password.png',
          label: 'Change password',
          onTap: () => _showUnavailable(context, 'Change password'),
        ),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/restore_purchases.png',
          label: 'Restore purchases',
          onTap: () => _showUnavailable(context, 'Restore purchases'),
        ),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/manage_subscription.png',
          label: 'Manage subscription',
          onTap: () => _showUnavailable(context, 'Manage subscription'),
        ),
        const _SectionTitle('Notifications'),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/Reminders.png',
          label: 'Reminders',
          onTap: () => _showUnavailable(context, 'Reminders'),
        ),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/reminder_time.png',
          label: 'Reminder time',
          onTap: () => _showUnavailable(context, 'Reminder time'),
        ),
        const _SectionTitle('Danger'),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/delete.png',
          label: 'Delete account',
          onTap: () => _showUnavailable(context, 'Delete account'),
        ),
        const _SectionTitle('Help'),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/faq.png',
          label: 'FAQs',
          onTap: () => _showUnavailable(context, 'FAQs'),
        ),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/terms_conditions.png',
          label: 'Terms and Conditions',
          onTap: () => _showUnavailable(context, 'Terms and Conditions'),
        ),
        _SettingsTile(
          iconAsset: 'assets/settingIcons/privacy_policy.png',
          label: 'Privacy policy',
          onTap: () => _showUnavailable(context, 'Privacy policy'),
        ),
        const _Footer(),
      ],
    );
  }

  static void _showUnavailable(BuildContext context, String feature) {
    showMessagePopup(context, message: '$feature coming soon');
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
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Log out',
              style: TextStyle(color: SettingScreen._green),
            ),
          ),
        ],
      ),
    );
  }
}
