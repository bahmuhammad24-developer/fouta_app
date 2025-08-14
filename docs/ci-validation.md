# CI Validation
The validate workflow runs before merges:

- Pubspec duplicate-key and formatting check (shell-based; no extra Dart packages).
- Color-contrast accessibility checks.
- flutter pub get to ensure dependency resolution.

## Important
Do not add yaml_lint (or similar) to dev_dependencies; our duplicate-key check is shell-based.

If flutter pub get fails, check for:

- malformed YAML (indentation, duplicate keys);
- missing/invalid package versions;
- corrupted lock/cache (fix by removing pubspec.lock, .dart_tool, then running flutter clean && flutter pub get).

## Run Locally
```bash
bash scripts/validate.sh
flutter analyze
```
