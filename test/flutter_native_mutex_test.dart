import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_native_mutex/flutter_native_mutex.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('winkk/flutter_native_mutex');
  final calls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('preserves key and returns callback value before unlocking', () async {
    final mutex = NativeMutex(globalKey: 'auth_ä/refresh');
    expect(await mutex.protect(() async => 42), 42);
    expect(calls.map((call) => call.method), ['lock', 'unlock']);
    expect(calls.map((call) => call.arguments), [
      {'globalKey': mutex.globalKey},
      {'globalKey': mutex.globalKey},
    ]);
  });

  test('callback exception unlocks and allows repeated use', () async {
    final mutex = NativeMutex(globalKey: 'key');
    final failure = StateError('callback');
    await expectLater(
        mutex.protect(() async => throw failure), throwsA(same(failure)));
    expect(await mutex.protect(() async => 7), 7);
    expect(
        calls.map((call) => call.method), ['lock', 'unlock', 'lock', 'unlock']);
  });

  test('callback waits for lock acknowledgement', () async {
    final requested = Completer<void>();
    final acquired = Completer<void>();
    var entered = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'lock') {
        requested.complete();
        await acquired.future;
      }
      return null;
    });
    final pending =
        NativeMutex(globalKey: 'key').protect(() async => entered = true);
    await requested.future;
    expect(entered, isFalse);
    acquired.complete();
    await pending;
    expect(entered, isTrue);
    expect(calls.last.method, 'unlock');
  });

  test('failed lock neither enters callback nor unlocks', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      throw PlatformException(code: 'Invalid argument');
    });
    await expectLater(
        NativeMutex(globalKey: 'key').protect(() async => fail('entered')),
        throwsA(isA<PlatformException>()));
    expect(calls.map((call) => call.method), ['lock']);
  });
}
