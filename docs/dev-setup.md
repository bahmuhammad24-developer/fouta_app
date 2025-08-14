# Developer Setup

## Dependency Resolution & Lockfile
We do not track `pubspec.lock` in version control for this app. CI runs `flutter pub get` to resolve dependencies.

If you see errors like:
```
Error on line N of pubspec.lock: Content-hash has incorrect length
```
or an empty sha256 for a package:

Fix locally (from the project root):

### Windows (PowerShell):
```
del .\pubspec.lock -ErrorAction SilentlyContinue
rmdir .\.dart_tool -Recurse -Force -ErrorAction SilentlyContinue
del .\.packages -ErrorAction SilentlyContinue
flutter clean
flutter pub get
```

### macOS/Linux (bash):
```
rm -f pubspec.lock
rm -rf .dart_tool .packages
flutter clean
flutter pub get
```

### Notes
- Make sure `pubspec.yaml` contains each dependency only once.
- Indentation must be 2 spaces (no tabs).
- CI runs `flutter pub get` and does not rely on a committed lockfile.
