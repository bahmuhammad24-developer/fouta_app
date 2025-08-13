import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/composer_v2/drafts_service.dart';

void main() {
  test('save and list drafts', () async {
    final firestore = FakeFirebaseFirestore();
    final service = DraftsService(firestore: firestore);
    await service.saveDraft('u1', 'd1', content: 'hello', media: ['m1']);
    final drafts = await service.listDrafts('u1');
    expect(drafts.length, 1);
    expect(drafts.first['content'], 'hello');
    expect(drafts.first['media'], ['m1']);
    await service.deleteDraft('u1', 'd1');
    final empty = await service.listDrafts('u1');
    expect(empty, isEmpty);
  });
}
