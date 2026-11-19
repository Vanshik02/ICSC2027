import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch published conference information
  Stream<DocumentSnapshot<Map<String, dynamic>>> getConferenceInfo() {
    return _db.collection('conference_info').doc('main').snapshots();
  }

  // Fetch published speakers
  Stream<QuerySnapshot<Map<String, dynamic>>> getSpeakers() {
    return _db
        .collection('speakers')
        .where('isPublished', isEqualTo: true)
        .snapshots();
  }

  // Fetch published conference sessions
  Stream<QuerySnapshot<Map<String, dynamic>>> getSessions() {
    return _db
        .collection('sessions')
        .where('isPublished', isEqualTo: true)
        .snapshots();
  }

  // Fetch published announcements
  Stream<QuerySnapshot<Map<String, dynamic>>> getAnnouncements() {
    return _db
        .collection('announcements')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Fetch published committees
  Stream<QuerySnapshot<Map<String, dynamic>>> getCommittees() {
    return _db
        .collection('committees')
        .where('isPublished', isEqualTo: true)
        .snapshots();
  }
}
