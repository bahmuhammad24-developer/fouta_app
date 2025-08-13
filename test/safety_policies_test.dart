import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/features/safety/muted_words_service.dart';
import 'package:fouta_app/features/safety/safety_service.dart';

void main() {
  test('canReply enforces limits and blocks', () async {
    final firestore = FakeFirebaseFirestore();
    const appId = 'app1';

    await firestore
        .doc('artifacts/$appId/public/data/users/author')
        .set({'followers': ['viewer']});
    await firestore
        .doc('artifacts/$appId/public/data/users/author/safety/settings')
        .set({'limitReplies': 'followers', 'blockedUserIds': []});
    await firestore
        .doc('artifacts/$appId/public/data/users/viewer/safety/settings')
        .set({'blockedUserIds': []});

    final service = SafetyService(
        firestore: firestore, appId: appId, userId: 'viewer');
    var allowed =
        await service.canReply(authorId: 'author', viewerId: 'viewer');
    expect(allowed, isTrue);

    await firestore
        .doc('artifacts/$appId/public/data/users/author')
        .set({'followers': []});
    allowed =
        await service.canReply(authorId: 'author', viewerId: 'viewer');
    expect(allowed, isFalse);

    await firestore
        .doc('artifacts/$appId/public/data/users/author/safety/settings')
        .set({'blockedUserIds': ['viewer']});
    allowed =
        await service.canReply(authorId: 'author', viewerId: 'viewer');
    expect(allowed, isFalse);
  });

  test('MutedWordsService shouldHide detects words', () async {
    final firestore = FakeFirebaseFirestore();
    const appId = 'app1';
    final service =
        MutedWordsService(firestore: firestore, appId: appId, userId: 'u1');
    await service.addWord('spoiler');
    expect(await service.shouldHide('This has a Spoiler'), isTrue);
    expect(await service.shouldHide('Clean text'), isFalse);
  });
}
