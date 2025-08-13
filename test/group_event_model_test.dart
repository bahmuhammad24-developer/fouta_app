import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/features/groups/groups_service.dart';
import 'package:fouta_app/features/events/events_service.dart';

void main() {
  group('Group.fromMap', () {
    test('parses mixed memberIds', () {
      final data = {
        'name': 'g',
        'ownerId': 'o',
        'memberIds': [1, '2', 3],
      };
      final group = Group.fromMap('id', data);
      expect(group.memberIds, ['1', '2', '3']);
    });
  });

  group('Event.fromMap', () {
    test('parses mixed RSVP lists', () {
      final data = {
        'title': 'e',
        'start': Timestamp.fromDate(DateTime(2020)),
        'end': Timestamp.fromDate(DateTime(2020, 1, 2)),
        'ownerId': 'o',
        'attendingIds': [1, '2'],
        'interestedIds': 3,
      };
      final event = Event.fromMap('id', data);
      expect(event.attendingIds, ['1', '2']);
      expect(event.interestedIds, <String>[]);
    });
  });
}
