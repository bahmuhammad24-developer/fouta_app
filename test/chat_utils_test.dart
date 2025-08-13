import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/services/chat_utils.dart';
import 'package:fouta_app/models/message.dart';

void main() {
  test('typing indicator logic', () {
    expect(otherUsersTyping(['a'], 'b'), true);
    expect(otherUsersTyping(['a', 'b'], 'b'), true);
    expect(otherUsersTyping(['b'], 'b'), false);
  });

  test('read receipt stamp', () {
    expect(statusFromReadAt({'a': 1}, 'a'), MessageStatus.sent);
    expect(statusFromReadAt({'a': 1, 'b': 2}, 'a'), MessageStatus.read);
  });
}
