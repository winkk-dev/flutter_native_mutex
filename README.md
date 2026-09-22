# flutter_native_mutex

A Flutter mutex shared by isolates within the same application process on Android and iOS.

```dart
final mutex = NativeMutex(globalKey: 'auth-refresh');
final result = await mutex.protect(() async {
  return refreshToken();
});
```

Use the same key to serialize access to a shared resource. Different keys may run concurrently. Native waiters receive the lock in request order, without blocking native worker threads. The lock is released when the callback returns or throws.

Locks are not reentrant: do not acquire the same key recursively. Background isolates must initialize `BackgroundIsolateBinaryMessenger` with the root isolate token before using platform channels. An isolate must remain alive until its `protect` call completes; killing an owner or queued isolate does not cancel its native lock. This is an in-process lock, not a cross-process or persistent lock.

## Compatibility

Version 0.1.0 requires Flutter 3.47+, Dart 3.13+, Android API 24+, and iOS 15+. Android uses Java 17 bytecode and supports AGP 9 built-in Kotlin. Hosts opting out of built-in Kotlin use Flutter's KGP compatibility handling; the plugin no longer applies the legacy Kotlin Android plugin itself. SwiftPM is the preferred iOS integration, with CocoaPods packaging retained.

The example uses AGP 9.4.1, Gradle 9.7.1, and Kotlin 2.4.20. Keep `android.newDsl=false` while Flutter 3.47 depends on the legacy AGP variant API. Updating the Swift compiler does not require opting into Swift 6 language mode.

## Development

Use Flutter 3.47.5 for current-stable validation. Run `flutter analyze` and `flutter test` at the repository root, then `flutter test` in `example`.

From `example/android`, run `./gradlew :flutter_native_mutex:testDebugUnitTest` with JDK 17 or 21. From `example`, run `flutter test integration_test/plugin_integration_test.dart -d <device-id>` on Android and iOS to verify cross-isolate serialization, independent keys, and exception recovery.

After `flutter build ios --simulator --debug` in `example`, run the Runner XCTest scheme with an available iOS simulator:

```sh
cd ios
xcodebuild test -workspace Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,id=<simulator-id>' \
  CODE_SIGNING_ALLOWED=NO
```
