# flutter_native_mutex

A Flutter mutex shared by isolates within the same application process on Android and iOS.

```dart
final mutex = NativeMutex(globalKey: 'auth-refresh');
final result = await mutex.protect(() async {
  return refreshToken();
});
```

Use the same key to serialize access to a shared resource. Different keys may run concurrently. The lock is released when the callback returns or throws. Locks are not reentrant: do not acquire the same key recursively. Background isolates must initialize `BackgroundIsolateBinaryMessenger` with the root isolate token before using platform channels.

## Development

The example targets Flutter 3.47+ with AGP 9.1, Gradle 9.3.1, built-in Kotlin, Java 17, and SwiftPM/UIScene on iOS 15+. The plugin retains CocoaPods packaging and the legacy Kotlin host compatibility path. Dart 3.8+ is required.

Run `flutter analyze` and `flutter test` at the repository root. From `example`, run `flutter test integration_test/plugin_integration_test.dart -d <device-id>` on Android and iOS to verify cross-isolate serialization, independent keys, and exception recovery.
