import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  int selectedDay = 0;

  bool savedLoaded = false;

  Set<String> savedSessions = {};

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
      savedSessions = (prefs.getStringList('icsc_saved_sessions') ?? [])
          .toSet();
      savedLoaded = true;
    });
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
        child: Column(
          children: [
            _header(),
            _daySelector(),

            Expanded(
              child: !savedLoaded
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.blue),
                    )
                  : _sessionContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      child: Row(
        children: [
          const Expanded(
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
                  'My Schedule',
                  style: TextStyle(
                    color: AppTheme.navy,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Build your personal conference agenda.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FC),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.bookmark_rounded,
              color: AppTheme.blue,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  Widget _daySelector() {
    return SizedBox(
      height: 65,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: conferenceDays.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = selectedDay == index;
          final date = conferenceDays[index];

          return GestureDetector(
            onTap: () => setState(() => selectedDay = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 13),
              decoration: BoxDecoration(
                color: selected ? AppTheme.navy : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppTheme.navy : AppTheme.border,
                ),
              ),
              child: Center(
                child: Text(
                  DateFormat('dd MMM').format(date).toUpperCase(),
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sessionContent() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestoreService.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Unable to Load Sessions',
            message: 'Please check your internet connection and try again.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.blue),
          );
        }

        final selectedDate = conferenceDays[selectedDay];

        final sessions =
            snapshot.data?.docs.where((doc) {
              final data = doc.data();
              final sessionDate = _parseSessionDate(data['date']);

              final matchesDate =
                  sessionDate != null &&
                  sessionDate.year == selectedDate.year &&
                  sessionDate.month == selectedDate.month &&
                  sessionDate.day == selectedDate.day;

              final matchesSaved = savedSessions.contains(doc.id);

              return matchesDate && matchesSaved;
            }).toList() ??
            [];

        sessions.sort((a, b) {
          return _timeSortValue(
            a.data()['startTime'],
          ).compareTo(_timeSortValue(b.data()['startTime']));
        });

        if (sessions.isEmpty) {
          return _emptyState(
            icon: Icons.bookmark_border_rounded,
            title: 'No Saved Sessions',
            message:
                'You have not bookmarked any sessions for this day. Go to Conference Programme and tap the bookmark icon to add sessions.',
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final doc = sessions[index];

            return _sessionCard(doc.data());
          },
        );
      },
    );
  }

  Widget _sessionCard(Map<String, dynamic> data) {
    final title = (data['title'] ?? 'Untitled session').toString();
    final startTime = (data['startTime'] ?? '').toString();
    final endTime = (data['endTime'] ?? '').toString();
    final venue = (data['venue'] ?? '').toString();
    final description = (data['description'] ?? '').toString();

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
                  ],
                ),
                const SizedBox(height: 9),
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

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FB),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: AppTheme.blue, size: 34),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '14–16 JANUARY 2027',
                  style: TextStyle(
                    color: AppTheme.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
