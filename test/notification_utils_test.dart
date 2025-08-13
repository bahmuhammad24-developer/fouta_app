import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/utils/notification_utils.dart';

void main() {
  test('filters disabled notification types', () {
    final items = [
      {'type': 'likes'},
      {'type': 'comments'},
    ];
    final prefs = defaultNotificationPrefs();
    prefs['likes'] = false;
    final filtered = filterNotifications(items, prefs);
    expect(filtered.length, 1);
    expect(filtered.first['type'], 'comments');
  });
}
