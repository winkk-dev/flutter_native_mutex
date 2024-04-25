import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_native_mutex_method_channel.dart';

abstract class FlutterNativeMutexPlatform extends PlatformInterface {
  /// Constructs a FlutterNativeMutexPlatform.
  FlutterNativeMutexPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterNativeMutexPlatform _instance = MethodChannelFlutterNativeMutex();

  /// The default instance of [FlutterNativeMutexPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterNativeMutex].
  static FlutterNativeMutexPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterNativeMutexPlatform] when
  /// they register themselves.
  static set instance(FlutterNativeMutexPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
