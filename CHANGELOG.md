## 0.1.0

* Require Flutter 3.47/Dart 3.13, Android API 24, and iOS 15 or newer.
* Fix the Android lock-entry removal race with atomic registration and FIFO handoff, removing the incidental coroutine dependency.
* Queue iOS lock callbacks without blocking a native worker thread for each waiter; invoke callbacks outside registry synchronization.
* Remove legacy Kotlin plugin application and update the Android example to AGP 9.4.1, Gradle 9.7.1, and Kotlin 2.4.20 with Java 17 targets.
* Replace the stale iOS platform-version test and add Android handoff, cross-instance, reuse, and concurrent acquisition coverage.
* Remove unused example icon assets dependency and correct CocoaPods metadata.

## 0.0.3

* Update examples for Flutter 3.47: AGP 9.1, Gradle 9.3.1, built-in Kotlin, Java 17, and iOS 15 with SwiftPM/UIScene.
* Upgrade Flutter lints to 6 and remove the unused platform-interface dependency (Dart 3.8+).
* Update Mockito to 5.23 for Java 21-compatible native unit tests.

## 0.0.2 

* Support host-selected built-in Kotlin while retaining legacy KGP and JVM target alignment.
* Add SwiftPM packaging using the unchanged CocoaPods Swift implementation.
* Declare the host-generated FlutterFramework SwiftPM dependency explicitly; older hosts retain CocoaPods support.
* Use standard Kotlin source directories without legacy Java source-set registration.

## 0.0.1

* TODO: Describe initial release.
