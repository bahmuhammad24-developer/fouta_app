import 'dart:io';

void main() {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    stderr.writeln('pubspec.yaml not found');
    exit(2);
  }
  final lines = file.readAsLinesSync();

  bool isTopLevel(String line) =>
      RegExp(r'^[A-Za-z_][A-Za-z0-9_]*\s*:').hasMatch(line.trimLeft()) &&
      !line.startsWith('  ');
  final keyLine = RegExp(r'^\s{2}([A-Za-z0-9_]+)\s*:');

  int scanSection(String name) {
    final start = lines.indexWhere((l) => l.trim() == '$name:');
    if (start == -1) return 0;
    final seen = <String,int>{};
    for (int i = start + 1; i < lines.length; i++) {
      final line = lines[i];
      if (isTopLevel(line)) break;
      final m = keyLine.firstMatch(line);
      if (m != null) {
        final k = m.group(1)!;
        seen.update(k, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    int dupes = 0;
    seen.forEach((k, v) {
      if (v > 1) {
        stderr.writeln('Duplicate in $name: $k appears $v times');
        dupes += v - 1;
      }
    });
    return dupes;
  }

  final totalDupes = scanSection('dependencies')
                   + scanSection('dev_dependencies')
                   + scanSection('dependency_overrides');

  if (totalDupes == 0) {
    print('No duplicate keys detected in pubspec.yaml');
    exit(0);
  } else {
    exit(1);
  }
}
