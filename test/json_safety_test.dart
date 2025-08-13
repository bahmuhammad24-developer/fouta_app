import 'package:flutter_test/flutter_test.dart';
import 'package:fouta_app/utils/json_safety.dart';

void main() {
  test('asInt parses values', () {
    expect(asInt('3'), 3);
    expect(asInt(null, fallback: 1), 1);
  });

  test('asDoubleOrNull parses', () {
    expect(asDoubleOrNull('1.5'), 1.5);
    expect(asDoubleOrNull('x'), isNull);
  });

  test('asStringList parses', () {
    expect(asStringList(['a', 2, null]), ['a', '2']);
  });

  test('asListOf filters types', () {
    expect(asListOf<int>([1, '2', 3]), [1, 3]);
  });
}
