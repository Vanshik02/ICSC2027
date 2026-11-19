import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.blue),
            );
          }

          if (snapshot.hasError) {
            return _buildMessage(
              icon: Icons.error_outline_rounded,
              title: 'Firestore Error',
              message: snapshot.error.toString(),
            );
          }

          final announcements = snapshot.data?.docs ?? [];

          if (announcements.isEmpty) {
            return _buildMessage(
              icon: Icons.notifications_none_rounded,
              title: 'You’re All Caught Up!',
              message:
                  'Conference announcements, programme updates '
                  'and important notifications will appear here.',
            );
          }

          return RefreshIndicator(
            color: AppTheme.blue,
            onRefresh: () async {
              await FirebaseFirestore.instance
                  .collection('announcements')
                  .where('isPublished', isEqualTo: true)
                  .get(const GetOptions(source: Source.server));
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'LATEST UPDATES',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                ...announcements.map((doc) {
                  final data = doc.data();

                  final title = data['title']?.toString() ?? 'Announcement';

                  final message =
                      data['message']?.toString() ??
                      data['description']?.toString() ??
                      '';

                  final createdAt = data['createdAt'];

                  String dateText = '';

                  if (createdAt is Timestamp) {
                    dateText = _formatDate(createdAt.toDate());
                  }

                  return _announcementCard(
                    title: title,
                    message: message,
                    date: dateText,
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _announcementCard({
    required String title,
    required String message,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppTheme.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.verified_rounded, color: Colors.green, size: 19),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FC),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, size: 43, color: AppTheme.blue),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }
}
