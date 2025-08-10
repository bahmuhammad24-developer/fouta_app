import 'dart:convert';
import 'dart:io';
import 'dart:math';

double _linear(double channel) {
  final c = channel / 255.0;
  return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(int r, int g, int b) {
  return 0.2126 * _linear(r) + 0.7152 * _linear(g) + 0.0722 * _linear(b);
}

double _contrast(List<int> a, List<int> b) {
  final la = _luminance(a[0], a[1], a[2]) + 0.05;
  final lb = _luminance(b[0], b[1], b[2]) + 0.05;
  return la > lb ? la / lb : lb / la;
}

List<int> _parse(String hex) {
  hex = hex.replaceFirst('#', '');
  final value = int.parse(hex, radix: 16);
  return [
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];
}

void main() {
  final data = jsonDecode(File('brand/tokens.json').readAsStringSync());
  final light = data['colors']['light'];
  final dark = data['colors']['dark'];
  final pairs = [
    ['primary', 'onPrimary'],
    ['secondary', 'onSecondary'],
    ['background', 'onBackground'],
  ];
  for (final p in pairs) {
    final lRatio = _contrast(_parse(light[p[0]]), _parse(light[p[1]]));
    final dRatio = _contrast(_parse(dark[p[0]]), _parse(dark[p[1]]));
    if (lRatio < 4.5 || dRatio < 4.5) {
      stderr.writeln('Contrast check failed for pair ${p[0]}/${p[1]}');
      exit(1);
    }
  }
  print('Contrast check passed');
}
