import 'dart:convert';
import 'dart:io';
import 'dart:math';

double _srgbChannelToLinear(int channel) {
  // Convert 0–255 int to 0–1 double, then to linear space
  final double x = channel.toDouble() / 255.0;
  return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4).toDouble();
}

List<int> _hexToRgb(String hex) {
  var h = hex.replaceAll('#', '').toUpperCase();
  if (h.length == 3) {
    // #RGB -> #RRGGBB
    h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
  }
  if (h.length == 8) {
    // Drop alpha if #AARRGGBB
    h = h.substring(2);
  }
  if (h.length != 6) {
    throw ArgumentError('Unsupported hex color: $hex');
  }
  final r = int.parse(h.substring(0, 2), radix: 16);
  final g = int.parse(h.substring(2, 4), radix: 16);
  final b = int.parse(h.substring(4, 6), radix: 16);
  return [r, g, b];
}

double _luminance(String hex) {
  final rgb = _hexToRgb(hex);
  final R = _srgbChannelToLinear(rgb[0]);
  final G = _srgbChannelToLinear(rgb[1]);
  final B = _srgbChannelToLinear(rgb[2]);
  // Relative luminance (WCAG)
  return 0.2126 * R + 0.7152 * G + 0.0722 * B;
}

double contrast(String a, String b) {
  final L1 = _luminance(a);
  final L2 = _luminance(b);
  final hi = max(L1, L2);
  final lo = min(L1, L2);
  return (hi + 0.05) / (lo + 0.05);
}

void _checkPair(String label, String fg, String bg, double minRatio, List<String> failures) {
  final r = contrast(fg, bg);
  final ok = r >= minRatio;
  final line = '${ok ? 'OK  ' : 'FAIL'} $label ${r.toStringAsFixed(2)} (>= ${minRatio.toStringAsFixed(1)})';
  print(line);
  if (!ok) failures.add(line);
}

void main() {
  final warnOnly = (Platform.environment['WARN_ONLY'] ?? 'false').toLowerCase() == 'true';

  final f = File('brand/tokens.json');
  if (!f.existsSync()) {
    print('WARN: brand/tokens.json not found; skipping contrast check.');
    return;
  }
  final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  final colors = (json['colors'] as Map<String, dynamic>);
  final light = (colors['light'] as Map<String, dynamic>).cast<String, String>();
  final dark  = (colors['dark']  as Map<String, dynamic>).cast<String, String>();

  const minAA = 4.5; // WCAG AA for normal text

  final failures = <String>[];
  _checkPair('light onPrimary/primary',     light['onPrimary']!,   light['primary']!,   minAA, failures);
  _checkPair('light onSecondary/secondary', light['onSecondary']!, light['secondary']!, minAA, failures);
  _checkPair('light onSurface/surface',     light['onSurface']!,   light['surface']!,   minAA, failures);
  _checkPair('light onError/error',         light['onError']!,     light['error']!,     minAA, failures);

  _checkPair('dark onPrimary/primary',      dark['onPrimary']!,    dark['primary']!,    minAA, failures);
  _checkPair('dark onSecondary/secondary',  dark['onSecondary']!,  dark['secondary']!,  minAA, failures);
  _checkPair('dark onSurface/surface',      dark['onSurface']!,    dark['surface']!,    minAA, failures);
  _checkPair('dark onError/error',          dark['onError']!,      dark['error']!,      minAA, failures);

  if (failures.isNotEmpty) {
    final msg = 'Contrast check failed for ${failures.length} pair(s).';
    if (warnOnly) {
      print('WARN_ONLY=true → not failing CI.\n$msg\n${failures.join('\n')}');
    } else {
      stderr.writeln('$msg\n${failures.join('\n')}');
      exit(1);
    }
  }
}
