import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../notifications/notifications_screen.dart';
import '../../constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../more/website_screen.dart';
import '../more/venue_screen.dart';
import 'dart:async';
class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  static final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestoreService.getConferenceInfo(),
      builder: (context, snapshot) {
        final info = snapshot.data?.data() ?? <String, dynamic>{};

        final startDate = _parseDate(
          info['startDate'],
          AppConstants.conferenceStart,
        );
        final endDate = _parseDate(info['endDate'], AppConstants.conferenceEnd);
        final dateText =
            '${DateFormat('dd MMM').format(startDate)} – '
            '${DateFormat('dd MMM yyyy').format(endDate)}';
        final heroDateText =
            '${DateFormat('dd').format(startDate)} – '
            '${DateFormat('dd MMMM yyyy').format(endDate)}';
        final venue = (info['venue'] as String?) ?? AppConstants.venue;
        final website = (info['website'] as String?) ?? AppConstants.website;
        final recordNumber =
            (info['ieeeRecordNumber'] as String?) ??
            AppConstants.ieeeRecordNumber;
      

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: _topBar(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _heroSection(
                    dateText: heroDateText,
                    venue: venue,
                    recordNumber: recordNumber,
                    startDate: startDate,
                    onCountdownTap: () => onNavigate(1),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _announcementsSection()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: _sectionHeading(
                      'Explore ICSC',
                      'Everything you need for the conference',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _featureGrid(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    child: _sectionHeading(
                      'Research & Innovation',
                      'Connect ideas. Discover possibilities.',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _researchCard(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    child: _sectionHeading(
                      'Conference Information',
                      'Plan your participation',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                    child: _informationCard(
                      context,
                      dateText: dateText,
                      venue: venue,
                      website: website,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  DateTime _parseDate(dynamic value, DateTime fallback) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      try {
        return DateFormat('d MMMM yyyy').parseStrict(value);
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  Widget _announcementsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestoreService.getAnnouncements(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading(
                'Latest Updates',
                'News from the conference team',
              ),
              const SizedBox(height: 13),
              ...docs.take(3).map((doc) {
                final data = doc.data();
                final title = (data['title'] as String?) ?? 'Conference update';
                final message =
                    (data['message'] as String?) ??
                    (data['content'] as String?) ??
                    '';
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FB),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: AppTheme.blue,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: AppTheme.textDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (message.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.navy, AppTheme.navyLight],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ICSC 2027',
                style: TextStyle(
                  color: AppTheme.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'CONFERENCE COMPANION',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.navy,
            ),
          ),
        ),
      ],
    );
  }

Widget _heroSection({
  required String dateText,
  required String venue,
  required String recordNumber,
  required DateTime startDate,
  required VoidCallback onCountdownTap,
}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [
          Color(0xFF08182B),
          Color(0xFF10385F),
          Color(0xFF15548A),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.navy.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: CustomPaint(painter: SignalWavePainter()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(23),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sensors_rounded,
                      size: 14,
                      color: AppTheme.electricBlue,
                    ),
                    SizedBox(width: 7),
                    Text(
                      '11TH INTERNATIONAL CONFERENCE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'SIGNAL PROCESSING',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '& COMMUNICATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ideas, research and innovation in a connected world.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 25),
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.16),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppTheme.gold,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      dateText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      venue,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tappable countdown card
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  onTap: onCountdownTap,
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 43,
                          width: 43,
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            color: AppTheme.gold,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'COUNTDOWN TO CONFERENCE',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 9,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              ConferenceCountdown(startDate: startDate),
                            ],
                          ),
                        ),
                        
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'IEEE CONFERENCE RECORD NO. $recordNumber',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _featureGrid() {
    final features = [
      (
        Icons.calendar_month_rounded,
        'Programme',
        'Sessions & timings',
        1,
        Color(0xFFE8F1FC),
        Color(0xFF2366A5),
      ),
      (
        Icons.groups_rounded,
        'Speakers',
        'Meet the experts',
        2,
        Color(0xFFEAF5F3),
        Color(0xFF278477),
      ),
      (
        Icons.article_rounded,
        'Research',
        'Papers & themes',
        3,
        Color(0xFFF2EDFA),
        Color(0xFF7956A6),
      ),
      (
        Icons.account_balance_rounded,
        'Conference',
        'Details & committees',
        3,
        Color(0xFFFCF2E5),
        Color(0xFFAD7835),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.38,
      ),
      itemBuilder: (context, index) {
        final item = features[index];

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          child: InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: () => onNavigate(item.$4),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 39,
                    width: 39,
                    decoration: BoxDecoration(
                      color: item.$5,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.$1, color: item.$6, size: 21),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.$3,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

Widget _researchCard(BuildContext context) {
  return Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(21),
    child: InkWell(
      borderRadius: BorderRadius.circular(21),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const WebsiteScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FB),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: const Color(0xFFD9E7F5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RESEARCH • TECHNOLOGY • INNOVATION',
                    style: TextStyle(
                      color: AppTheme.blue,
                      fontSize: 8,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Where ideas meet innovation.',
                    style: TextStyle(
                      color: AppTheme.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Explore the conference and its research focus.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'DISCOVER ICSC 2027  →',
                    style: TextStyle(
                      color: AppTheme.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 82,
              width: 82,
              decoration: BoxDecoration(
                color: AppTheme.navy,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                size: 43,
                color: AppTheme.electricBlue,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _informationCard(
    BuildContext context, {
    required String dateText,
    required String venue,
    required String website,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _informationRow(
            Icons.calendar_today_rounded,
            'Conference dates',
            dateText,
          ),
          const Divider(height: 27, color: AppTheme.border),
          _informationRow(
            Icons.location_on_rounded,
            'Venue',
            venue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VenueScreen()),
              );
            },
          ),
          const Divider(height: 27, color: AppTheme.border),
          _informationRow(
            Icons.language_rounded,
            'Official website',
            website.replaceFirst(RegExp(r'^https?://'), ''),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WebsiteScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _informationRow(
    IconData icon,
    String title,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1F9),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppTheme.navyLight, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SignalWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = const Color(0xFF50B8FF).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final yOffset = size.height * (0.22 + i * 0.105);

      path.moveTo(0, yOffset);

      for (double x = 0; x <= size.width; x += 3) {
        final y =
            yOffset +
            (14 + i * 3) *
                (x / size.width) *
                (1 - x / size.width) *
                4 *
                (i.isEven ? 1 : -1) *
                (x / size.width * 6).abs().remainder(2);

        path.lineTo(x, y);
      }

      canvas.drawPath(path, wavePaint);
    }

    final dotPaint = Paint()
      ..color = const Color(0xFF50B8FF).withValues(alpha: 0.35);

    for (int i = 0; i < 22; i++) {
      final x = (i * 37.0) % size.width;
      final y = (i * 53.0) % size.height;
      canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class ConferenceCountdown extends StatefulWidget {
  final DateTime startDate;

  const ConferenceCountdown({
    super.key,
    required this.startDate,
  });

  @override
  State<ConferenceCountdown> createState() => _ConferenceCountdownState();
}

class _ConferenceCountdownState extends State<ConferenceCountdown> {
  late Timer _timer;

  int get daysLeft {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final conferenceDay = DateTime(
      widget.startDate.year,
      widget.startDate.month,
      widget.startDate.day,
    );

    return conferenceDay.difference(today).inDays;
  }

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void didUpdateWidget(covariant ConferenceCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = daysLeft;

    return Text(
      days > 0
          ? '$days days to go'
          : days == 0
              ? 'Conference starts today!'
              : 'Conference has started',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}