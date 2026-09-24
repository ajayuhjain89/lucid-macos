import Testing

/// Suites that read and clear the `lucid.*` keys in UserDefaults.standard
/// (LucidPreferences stores through @AppStorage). `.serialized` on each suite
/// only ordered its own tests, and the suites ran in parallel with each other:
/// on CI a new window picked up Focus Mode from a preset another suite had just
/// applied. Nested here, all of them run one at a time.
@Suite(.serialized)
enum UserDefaultsTests {}
