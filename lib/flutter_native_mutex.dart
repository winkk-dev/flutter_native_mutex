
import 'flutter_native_mutex_platform_interface.dart';

class FlutterNativeMutex {
  Future<String?> getPlatformVersion() {
    return FlutterNativeMutexPlatform.instance.getPlatformVersion();
  }
}
