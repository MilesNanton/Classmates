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
          onTap: () => _showManageSubscription(context),
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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      builder: (_) => const _SubscriptionSheet(),
    );
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
  static const _features = <String>[
    'Discover experiences & resources',
    'Connect with parents',
    'Join the conversation',
    'Personalised recommendations',
    'Build your family’s experience history',
  ];

  bool _yearly = false;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.76,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 20, 0),
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Subscribe to Classmates',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  color: const Color(0xFF181818),
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
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
            const SizedBox(height: 18),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  for (final feature in _features)
                    SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 18),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: () => showMessagePopup(
                        context,
                        message: 'Subscription checkout coming soon',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF08A948),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _yearly
                            ? 'Subscribe for £49.99 / year'
                            : 'Subscribe for £4.99 / month',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                fontSize: 13,
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
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    period,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF777777),
                      fontSize: 13,
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
