#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p build/validation

echo "== Check pubspec duplicates =="
if dart run tool/check_pubspec_dupes.dart | tee build/validation/pubspec_dupes.txt; then
  echo "No duplicate keys detected in pubspec.yaml"
else
  echo "Duplicate keys found in pubspec.yaml"
  exit 1
fi

echo "== Contrast check =="
dart run tool/contrast_check.dart

echo "== flutter pub get =="
flutter pub get
