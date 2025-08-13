import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../main.dart';
import '../../utils/json_safety.dart';

class Event {
  Event({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.location,
    this.description,
    this.coverUrl,
    required this.ownerId,
    required this.attendingIds,
    required this.interestedIds,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? location;
  final String? description;
  final String? coverUrl;
  final String ownerId;
  final List<String> attendingIds;
  final List<String> interestedIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Event.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Event(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      start: (data['start'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      end: (data['end'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      location: data['location']?.toString(),
      description: data['description']?.toString(),
      coverUrl: data['coverUrl']?.toString(),
      ownerId: data['ownerId']?.toString() ?? '',
      attendingIds: asStringList(data['attendingIds']),
      interestedIds: asStringList(data['interestedIds']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Event.fromMap(String id, Map<String, dynamic> data) => Event(
        id: id,
        title: data['title']?.toString() ?? '',
        start: (data['start'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
        end: (data['end'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
        location: data['location']?.toString(),
        description: data['description']?.toString(),
        coverUrl: data['coverUrl']?.toString(),
        ownerId: data['ownerId']?.toString() ?? '',
        attendingIds: asStringList(data['attendingIds']),
        interestedIds: asStringList(data['interestedIds']),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        if (location != null) 'location': location,
        if (description != null) 'description': description,
        if (coverUrl != null) 'coverUrl': coverUrl,
        'ownerId': ownerId,
        'attendingIds': attendingIds,
        'interestedIds': interestedIds,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class EventsService {
  EventsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection('artifacts')
      .doc(APP_ID)
      .collection('public')
      .doc('data')
      .collection('events');

  Future<String> createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? location,
    String? description,
    String? coverUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Missing user');
    final doc = await _collection.add({
      'title': title,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      if (location != null) 'location': location,
      if (description != null) 'description': description,
      if (coverUrl != null) 'coverUrl': coverUrl,
      'ownerId': uid,
      'attendingIds': [uid],
      'interestedIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<List<Event>> streamUpcomingEvents() {
    final now = Timestamp.now();
    return _collection
        .where('start', isGreaterThanOrEqualTo: now)
        .orderBy('start')
        .snapshots()
        .map((s) => s.docs.map(Event.fromDoc).toList());
  }

  Future<void> rsvp(String eventId, String userId, String status) async {
    final doc = _collection.doc(eventId);
    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (status == 'going') {
      updates['attendingIds'] = FieldValue.arrayUnion([userId]);
      updates['interestedIds'] = FieldValue.arrayRemove([userId]);
    } else if (status == 'interested') {
      updates['interestedIds'] = FieldValue.arrayUnion([userId]);
      updates['attendingIds'] = FieldValue.arrayRemove([userId]);
    } else {
      updates['attendingIds'] = FieldValue.arrayRemove([userId]);
      updates['interestedIds'] = FieldValue.arrayRemove([userId]);
    }
    await doc.update(updates);
  }
}

// TODO: expand roles for event moderators.
