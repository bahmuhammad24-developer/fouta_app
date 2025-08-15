# Challenges Feature Flag

The `CHALLENGES_ENABLED` compile-time flag gates the stubbed challenges feed and navigation wiring.

## Usage

### Local
Run the app with the flag enabled:

```sh
flutter run --dart-define=CHALLENGES_ENABLED=true
```

### CI
Optionally pass the same `--dart-define` to UI test jobs to exercise the stub feed.

## Notes
- The feed currently uses mock data until backend integrations land.
- When the flag is off (default), the Challenges route and nav entry are omitted.
