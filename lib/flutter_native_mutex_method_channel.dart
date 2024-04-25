import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_native_mutex_platform_interface.dart';

/// An implementation of [FlutterNativeMutexPlatform] that uses method channels.
class MethodChannelFlutterNativeMutex extends FlutterNativeMutexPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_native_mutex');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
