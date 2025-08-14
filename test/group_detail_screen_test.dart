import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fouta_app/features/groups/groups_service.dart';
import 'package:fouta_app/screens/group_detail_screen.dart';

class FakeGroupsService extends GroupsService {
  FakeGroupsService();

  @override
  Future<void> joinGroup(String groupId, String userId) async {}

  @override
  Future<void> leaveGroup(String groupId, String userId) async {}
}

void main() {
  testWidgets('joining a group updates button state', (tester) async {
    final group = Group(
      id: 'g1',
      name: 'Test',
      ownerId: 'owner',
      memberIds: [],
      roles: {'owner': 'owner'},
      description: null,
      coverUrl: null,
      createdAt: null,
    );
    final service = FakeGroupsService();
    await tester.pumpWidget(MaterialApp(
      home: GroupDetailScreen(
        group: group,
        service: service,
        currentUserId: 'user',
      ),
    ));

    expect(find.text('Join'), findsOneWidget);
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    expect(find.text('Leave'), findsOneWidget);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('Join'), findsOneWidget);
  });
}
