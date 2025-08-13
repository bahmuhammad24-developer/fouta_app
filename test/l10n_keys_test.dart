import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('l10n files contain same keys', () {
    final enFile = File('lib/l10n/app_en.arb');
    final frFile = File('lib/l10n/app_fr.arb');
    final enKeys = (json.decode(enFile.readAsStringSync()) as Map<String, dynamic>).keys.toSet();
    final frKeys = (json.decode(frFile.readAsStringSync()) as Map<String, dynamic>).keys.toSet();
    expect(enKeys, frKeys);
  });
}
