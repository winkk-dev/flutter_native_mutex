import Flutter
import UIKit

public class FlutterNativeMutexPlugin: NSObject, FlutterPlugin {
  private static var sharedMutexMap = [String: (semaphore: DispatchSemaphore, count: Int)]()
  private static let accessQueue = DispatchQueue(label: "com.winkk.nativeMutex.accessQueue")
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "winkk/flutter_native_mutex", binaryMessenger: registrar.messenger())
    let instance = FlutterNativeMutexPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "lock":
      guard let args = call.arguments as? [String: Any],
            let globalKey = args["globalKey"] as? String else {
          result(FlutterError(code: "Invalid argument", message: "globalKey is required", details: nil))
          return
      }
      FlutterNativeMutexPlugin.accessQueue.sync {
        var entry = FlutterNativeMutexPlugin.sharedMutexMap[globalKey] ?? (semaphore: DispatchSemaphore(value: 1), count: 0)
        entry.count += 1
        FlutterNativeMutexPlugin.sharedMutexMap[globalKey] = entry
        DispatchQueue.global().async {
          entry.semaphore.wait()
          DispatchQueue.main.async {
            result(nil)
          }
        }
      }
    case "unlock":
      guard let args = call.arguments as? [String: Any],
            let globalKey = args["globalKey"] as? String else {
          result(FlutterError(code: "Invalid argument", message: "globalKey is required", details: nil))
          return
      }
      FlutterNativeMutexPlugin.accessQueue.sync {
        guard var entry = FlutterNativeMutexPlugin.sharedMutexMap[globalKey] else {
          result(FlutterError(code: "Invalid argument", message: "mutex must be locked first", details: nil))
          return
        }
        entry.semaphore.signal()
        entry.count -= 1
        if entry.count == 0 {
          FlutterNativeMutexPlugin.sharedMutexMap.removeValue(forKey: globalKey)
        } else {
          FlutterNativeMutexPlugin.sharedMutexMap[globalKey] = entry
        }
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
