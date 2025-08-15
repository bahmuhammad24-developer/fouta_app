/// App feature flags (runtime decisions can read these).
const bool AR_EXPERIMENTAL = bool.fromEnvironment('AR_EXPERIMENTAL', defaultValue: false);
/// Centralized feature flags (compile-time via --dart-define).
const bool CHALLENGES_ENABLED =
    bool.fromEnvironment('CHALLENGES_ENABLED', defaultValue: false);
