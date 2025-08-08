import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/utils/date_utils.dart';
import 'package:intl/intl.dart';

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

  test('formatRelative handles weeks, month name, and years', () {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 10));
    final monthAgo = now.subtract(const Duration(days: 45));
    final yearsAgo = now.subtract(const Duration(days: 800));
    expect(DateUtilsHelper.formatRelative(weekAgo), '1 week ago');
    final expectedMonth = DateFormat('MMMM').format(monthAgo);
    expect(DateUtilsHelper.formatRelative(monthAgo), expectedMonth);
    expect(DateUtilsHelper.formatRelative(yearsAgo), '2 years ago');
  });
}

