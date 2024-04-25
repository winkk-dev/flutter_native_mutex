import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_native_mutex/flutter_native_mutex.dart';
import 'package:flutter_native_mutex/flutter_native_mutex_platform_interface.dart';
import 'package:flutter_native_mutex/flutter_native_mutex_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterNativeMutexPlatform
    with MockPlatformInterfaceMixin
    implements FlutterNativeMutexPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterNativeMutexPlatform initialPlatform = FlutterNativeMutexPlatform.instance;

  test('$MethodChannelFlutterNativeMutex is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterNativeMutex>());
  });

  test('getPlatformVersion', () async {
    FlutterNativeMutex flutterNativeMutexPlugin = FlutterNativeMutex();
    MockFlutterNativeMutexPlatform fakePlatform = MockFlutterNativeMutexPlatform();
    FlutterNativeMutexPlatform.instance = fakePlatform;

    expect(await flutterNativeMutexPlugin.getPlatformVersion(), '42');
  });
}
