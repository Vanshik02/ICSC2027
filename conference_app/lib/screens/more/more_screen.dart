
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'website_screen.dart';
import 'venue_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _openExternalLink(
    BuildContext context,
    String url,
  ) async {
    final uri = Uri.parse(url);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the link.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the link.')),
        );
      }
    }
  }

  void _openWebsite(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WebsiteScreen()),
    );
  }

  void _showInformation(
    BuildContext context,
    String title,
    String description,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _conferenceCard()),
            SliverToBoxAdapter(child: _sectionTitle('Conference')),
            SliverToBoxAdapter(
              child: _menuGroup(context, [
                _MenuItem(
                  Icons.info_outline_rounded,
                  'About ICSC',
                  'Conference overview and objectives',
                  const Color(0xFFE8F1FC),
                  AppTheme.blue,
                  () => _showInformation(
                    context,
                    'About ICSC 2027',
                    'The 11th International Conference on Signal Processing '
                        'and Communication (ICSC 2027) is scheduled for '
                        '14–16 January 2027 at Jaypee Institute of Information '
                        'Technology, Noida. Visit the official conference '
                        'website for confirmed conference information.',
                  ),
                ),
                _MenuItem(
                  Icons.groups_outlined,
                  'Committees',
                  'Organising and technical committees',
                  const Color(0xFFEAF5F3),
                  const Color(0xFF278477),
                  () => _openExternalLink(
                    context,
                    'https://lp.jiit.ac.in/ICSC/advisory.php',
                  ),
                ),
                _MenuItem(
                  Icons.location_on_outlined,
                  'Venue',
                  'JIIT, Noida',
                  const Color(0xFFFCF2E5),
                  const Color(0xFFAD7835),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VenueScreen()),
                    );
                  },
                ),
              ]),
            ),
            SliverToBoxAdapter(
              child: _sectionTitle('Research & Participation'),
            ),
            SliverToBoxAdapter(
              child: _menuGroup(context, [
                _MenuItem(
                  Icons.app_registration_rounded,
                  'Registration',
                  'Registration details and updates',
                  const Color(0xFFE8F1FC),
                  AppTheme.blue,
                  () => _openExternalLink(
                    context,
                    'https://lp.jiit.ac.in/ICSC/registration.php',
                  ),
                ),
              ]),
            ),
            SliverToBoxAdapter(child: _sectionTitle('Official Resources')),
            SliverToBoxAdapter(
              child: _menuGroup(context, [
                _MenuItem(
                  Icons.language_rounded,
                  'Official Website',
                  'Visit the ICSC conference website',
                  const Color(0xFFE8F1FC),
                  AppTheme.blue,
                  () => _openWebsite(context),
                ),
                _MenuItem(
                  Icons.verified_outlined,
                  'IEEE Record',
                  'Conference Record No. 71980',
                  const Color(0xFFFCF2E5),
                  const Color(0xFFAD7835),
                  () => _showInformation(
                    context,
                    'IEEE Conference Record',
                    'IEEE Conference Record Number: '
                        '${AppConstants.ieeeRecordNumber}',
                  ),
                ),
              ]),
            ),
            SliverToBoxAdapter(child: _footer()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ICSC 2027',
            style: TextStyle(
              color: AppTheme.blue,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Conference Information',
            style: TextStyle(
              color: AppTheme.navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Everything you need to know about ICSC 2027.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _conferenceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.navy, AppTheme.navyLight],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '11TH INTERNATIONAL CONFERENCE',
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: 9,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'ICSC 2027',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Signal Processing and Communication',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 17),
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: AppTheme.gold,
                size: 17,
              ),
              SizedBox(width: 7),
              Text(
                '14–16 January 2027',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 27, 20, 13),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.navy,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _menuGroup(BuildContext context, List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _menuTile(items[i]),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 53, color: AppTheme.border),
          ],
        ],
      ),
    );
  }

  Widget _menuTile(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: item.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.foreground, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textMuted,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 30, 20, 35),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_rounded,
            color: AppTheme.navyLight,
            size: 30,
          ),
          SizedBox(height: 10),
          Text(
            'ICSC 2027',
            style: TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Jaypee Institute of Information Technology, Noida',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
          SizedBox(height: 12),
          Text(
            'Official Conference Companion',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _MenuItem(
    this.icon,
    this.title,
    this.subtitle,
    this.background,
    this.foreground,
    this.onTap,
  );
}
