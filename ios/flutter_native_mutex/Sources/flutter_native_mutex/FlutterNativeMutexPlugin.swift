import Flutter
import UIKit

public class FlutterNativeMutexPlugin: NSObject, FlutterPlugin {
  // Presence marks an owner. Queued callbacks are handed the lock without blocking a thread.
  private static var sharedMutexMap = [String: [FlutterResult]]()
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
      let acquired = FlutterNativeMutexPlugin.accessQueue.sync {
        if FlutterNativeMutexPlugin.sharedMutexMap[globalKey] != nil {
          FlutterNativeMutexPlugin.sharedMutexMap[globalKey]!.append(result)
          return false
        }
        FlutterNativeMutexPlugin.sharedMutexMap[globalKey] = []
        return true
      }
      if acquired { result(nil) }
    case "unlock":
      guard let args = call.arguments as? [String: Any],
            let globalKey = args["globalKey"] as? String else {
          result(FlutterError(code: "Invalid argument", message: "globalKey is required", details: nil))
          return
      }
      let (wasLocked, next): (Bool, FlutterResult?) = FlutterNativeMutexPlugin.accessQueue.sync {
        guard var waiters = FlutterNativeMutexPlugin.sharedMutexMap[globalKey] else {
          return (false, nil)
        }
        if waiters.isEmpty {
          FlutterNativeMutexPlugin.sharedMutexMap.removeValue(forKey: globalKey)
          return (true, nil)
        }
        let next = waiters.removeFirst()
        FlutterNativeMutexPlugin.sharedMutexMap[globalKey] = waiters
        return (true, next)
      }
      // Callbacks may reenter the plugin, so never invoke them on accessQueue.
      if wasLocked {
        next?(nil)
        result(nil)
      } else {
        result(FlutterError(code: "Invalid argument", message: "mutex must be locked first", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
