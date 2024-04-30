import 'package:flutter/services.dart';

class NativeMutex {
  static const MethodChannel _channel = MethodChannel('winkk/flutter_native_mutex');

  /// Creates a new [NativeMutex] object.
  ///
  /// [globalKey] is a unique key to identify the mutex across all isolates.
  NativeMutex({
    required this.globalKey,
  });

  final String globalKey;

  /// Protects a critical section of code with a mutex.
  ///
  /// The return value of [criticalSection] is returned by this function after
  /// the critical section is done.
  Future<T> protect<T>(Future<T> Function() criticalSection) async {
    await _channel.invokeMethod('lock', {
      'globalKey': globalKey,
    });
    try {
      return await criticalSection();
    } finally {
      await _channel.invokeMethod('unlock', {
        'globalKey': globalKey,
      });
    }
  }
}