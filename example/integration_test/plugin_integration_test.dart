import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter_native_mutex/flutter_native_mutex.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void worker((RootIsolateToken, SendPort, String) args) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(args.$1);
  final commands = ReceivePort();
  args.$2.send(commands.sendPort);
  final pending = NativeMutex(globalKey: args.$3).protect(() async {
    args.$2.send('entered');
    await commands.first;
  });
  // A later native request on this messenger acknowledges that the shared-key
  // request was dispatched. Its completion must precede entry into the held key.
  await NativeMutex(globalKey: '${args.$3}-barrier').protect(() async {});
  args.$2.send('barrier');
  await pending;
  commands.close();
  args.$2.send('done');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('same-key isolates serialize and different keys progress',
      (_) async {
    final messages = ReceivePort();
    final events = StreamIterator(messages);
    final held = Completer<void>();
    final release = Completer<void>();
    final owner =
        NativeMutex(globalKey: 'integration-shared').protect(() async {
      held.complete();
      await release.future;
    });
    await held.future;
    final isolate = await Isolate.spawn(worker,
        (RootIsolateToken.instance!, messages.sendPort, 'integration-shared'));
    try {
      expect(await events.moveNext(), isTrue);
      final commands = events.current as SendPort;
      // Another key must complete while the first key is held.
      expect(
          await NativeMutex(globalKey: 'integration-other')
              .protect(() async => 42),
          42);
      expect(await events.moveNext(), isTrue);
      expect(events.current, 'barrier');
      release.complete();
      await owner;
      expect(await events.moveNext(), isTrue);
      expect(events.current, 'entered');
      commands.send('release');
      expect(await events.moveNext(), isTrue);
      expect(events.current, 'done');
      for (var i = 0; i < 20; i++) {
        expect(
            await NativeMutex(globalKey: 'integration-shared')
                .protect(() async => i),
            i);
      }
    } finally {
      if (!release.isCompleted) release.complete();
      isolate.kill(priority: Isolate.immediate);
      await events.cancel();
      messages.close();
    }
  });

  testWidgets('callback failure releases native lock', (_) async {
    final mutex = NativeMutex(globalKey: 'integration-exception');
    await expectLater(mutex.protect(() async => throw StateError('expected')),
        throwsStateError);
    expect(await mutex.protect(() async => 42), 42);
  });
}
