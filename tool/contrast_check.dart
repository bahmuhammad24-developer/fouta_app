import 'dart:math';

double _srgbToLinear(int c) {
  final x = c / 255.0;
  return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(String hex) {
  hex = hex.replaceAll('#', '');
  final r = int.parse(hex.substring(0, 2), radix: 16);
  final g = int.parse(hex.substring(2, 4), radix: 16);
  final b = int.parse(hex.substring(4, 6), radix: 16);
  final R = _srgbToLinear(r);
  final G = _srgbToLinear(g);
  final B = _srgbToLinear(b);
  return 0.2126 * R + 0.7152 * G + 0.0722 * B;
}

double contrast(String a, String b) {
  final L1 = _luminance(a);
  final L2 = _luminance(b);
  final hi = max(L1, L2);
  final lo = min(L1, L2);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const light = {
    'primary': '#7ED6A0',
    'onPrimary': '#000000',
    'secondary': '#F5D98B',
    'onSecondary': '#000000',
    'surface': '#FFFFFF',
    'onSurface': '#111418',
    'error': '#E85A5A',
    'onError': '#000000',
  };
  const dark = {
    'primary': '#3BAF7C',
    'onPrimary': '#000000',
    'secondary': '#E1C376',
    'onSecondary': '#1E1800',
    'surface': '#101D15',
    'onSurface': '#E4E8EA',
    'error': '#E2726E',
    'onError': '#000000',
  };

  final checks = [
    ['light onPrimary/primary', contrast(light['onPrimary']!, light['primary']!)],
    ['light onSecondary/secondary', contrast(light['onSecondary']!, light['secondary']!)],
    ['light onSurface/surface', contrast(light['onSurface']!, light['surface']!)],
    ['light onError/error', contrast(light['onError']!, light['error']!)],
    ['dark onPrimary/primary', contrast(dark['onPrimary']!, dark['primary']!)],
    ['dark onSecondary/secondary', contrast(dark['onSecondary']!, dark['secondary']!)],
    ['dark onSurface/surface', contrast(dark['onSurface']!, dark['surface']!)],
    ['dark onError/error', contrast(dark['onError']!, dark['error']!)],
  ];

  bool fail = false;
  for (final c in checks) {
    final ratio = (c[1] as double);
    if (ratio < 4.5) {
      fail = true;
      print('FAIL ${c[0]} contrast ${ratio.toStringAsFixed(2)} < 4.5');
    } else {
      print('OK   ${c[0]} contrast ${ratio.toStringAsFixed(2)}');
    }
  }
  if (fail) throw Exception('Contrast check failed');
}

