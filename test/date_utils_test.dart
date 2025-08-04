import 'package:test/test.dart';
import 'package:fouta_app/utils/date_utils.dart';

void main() {
  test('formatRelative handles future dates', () {
    final now = DateTime.now();
    final future = now.add(const Duration(minutes: 5));
    expect(DateUtilsHelper.formatRelative(future), 'In 5 mins');
  });

  test('formatRelative handles past dates', () {
    final now = DateTime.now();
    final past = now.subtract(const Duration(hours: 2));
    expect(DateUtilsHelper.formatRelative(past), '2 hours ago');
  });
}

