
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int selectedDay = 0;
  Set<String> savedSessions = {};
  bool savedLoaded = false;

  final FirestoreService firestoreService = FirestoreService();

  final List<DateTime> conferenceDays = List.generate(
    3,
    (index) => DateTime(2027, 1, 14 + index),
  );

  @override
  void initState() {
    super.initState();
    _loadSavedSessions();
  }

  Future<void> _loadSavedSessions() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      savedSessions =
          (prefs.getStringList('icsc_saved_sessions') ?? []).toSet();
      savedLoaded = true;
    });
  }

  Future<void> _toggleSavedSession(String sessionId) async {
    final updated = Set<String>.from(savedSessions);

    if (updated.contains(sessionId)) {
      updated.remove(sessionId);
    } else {
      updated.add(sessionId);
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'icsc_saved_sessions',
      updated.toList(),
    );

    if (!mounted) return;

    setState(() {
      savedSessions = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated.contains(sessionId)
              ? 'Session added to My Schedule'
              : 'Session removed from My Schedule',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  DateTime? _parseSessionDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is! String) return null;

    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;

    for (final format in [
      'd MMMM yyyy',
      'dd MMMM yyyy',
      'd MMM yyyy',
      'dd MMM yyyy',
      'dd/MM/yyyy',
    ]) {
      try {
        return DateFormat(format).parseStrict(value);
      } catch (_) {}
    }

    return null;
  }

  int _timeSortValue(dynamic value) {
    if (value == null) return 0;

    final time = value.toString().trim();

    for (final format in ['h:mm a', 'hh:mm a', 'HH:mm', 'h a']) {
      try {
        final parsed = DateFormat(format).parseStrict(time);
        return parsed.hour * 60 + parsed.minute;
      } catch (_) {}
    }

    return 0;
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
            SliverToBoxAdapter(child: _dateSelector()),
            SliverToBoxAdapter(child: _dayOverview()),
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: firestoreService.getSessions(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _messageCard(
                      icon: Icons.cloud_off_rounded,
                      title: 'Unable to Load Programme',
                      message:
                          'Please check your internet connection and try again.',
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 65),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.blue,
                        ),
                      ),
                    );
                  }

                  if (!savedLoaded) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 65),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.blue,
                        ),
                      ),
                    );
                  }

                  final selectedDate = conferenceDays[selectedDay];

                  // Keep the Firestore document ID with each session.
                  final sessions = snapshot.data?.docs
                          .where((doc) {
                            final data = doc.data();
                            final sessionDate =
                                _parseSessionDate(data['date']);

                            return sessionDate != null &&
                                sessionDate.year == selectedDate.year &&
                                sessionDate.month == selectedDate.month &&
                                sessionDate.day == selectedDate.day;
                          })
                          .toList() ??
                      [];

                  sessions.sort((a, b) {
                    return _timeSortValue(a.data()['startTime'])
                        .compareTo(
                      _timeSortValue(b.data()['startTime']),
                    );
                  });

                  if (sessions.isEmpty) {
                    return _messageCard(
                      icon: Icons.calendar_month_rounded,
                      title: 'Programme Coming Soon',
                      message:
                          'The official programme for this day will be published here once confirmed by the conference organisers.',
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 35),
                    child: Column(
                      children: sessions.map((doc) {
                        return _sessionCard(
                          doc.id,
                          doc.data(),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ICSC 2027',
            style: TextStyle(
              color: AppTheme.blue,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Conference Programme',
            style: TextStyle(
              color: AppTheme.navy,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Explore the three days of research and knowledge exchange.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: AppTheme.blue,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  '14 – 16 JANUARY 2027',
                  style: TextStyle(
                    color: AppTheme.navyLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateSelector() {
    return SizedBox(
      height: 105,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: conferenceDays.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = conferenceDays[index];
          final isSelected = selectedDay == index;

          return GestureDetector(
            onTap: () {
              setState(() => selectedDay = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.navy : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppTheme.navy : AppTheme.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.navy.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'DAY ${index + 1}',
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.gold
                          : AppTheme.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.navy,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white70
                          : AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dayOverview() {
    final date = conferenceDays[selectedDay];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE').format(date),
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy').format(date),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FB),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              'DAY ${selectedDay + 1} OF 3',
              style: const TextStyle(
                color: AppTheme.blue,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard(String sessionId, Map<String, dynamic> data) {
    final title = (data['title'] ?? 'Untitled session').toString();
    final startTime = (data['startTime'] ?? '').toString();
    final endTime = (data['endTime'] ?? '').toString();
    final venue = (data['venue'] ?? '').toString();
    final description = (data['description'] ?? '').toString();

    final isSaved = savedSessions.contains(sessionId);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 105,
            decoration: BoxDecoration(
              color: AppTheme.blue,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppTheme.blue,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        startTime.isEmpty
                            ? 'Time to be announced'
                            : endTime.isEmpty
                                ? startTime
                                : '$startTime - $endTime',
                        style: const TextStyle(
                          color: AppTheme.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _toggleSavedSession(sessionId),
                      icon: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: AppTheme.blue,
                      ),
                      tooltip: isSaved
                          ? 'Remove from My Schedule'
                          : 'Add to My Schedule',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                if (venue.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.textMuted,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          venue,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 35),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FB),
                borderRadius: BorderRadius.circular(19),
              ),
              child: Icon(icon, color: AppTheme.blue, size: 29),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: AppTheme.blue,
                    size: 19,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Check back for programme updates.',
                      style: TextStyle(
                        color: AppTheme.navyLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}