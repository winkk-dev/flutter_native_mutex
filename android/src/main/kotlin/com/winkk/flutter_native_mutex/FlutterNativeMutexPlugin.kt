package com.winkk.flutter_native_mutex

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.ArrayDeque

class FlutterNativeMutexPlugin: FlutterPlugin, MethodCallHandler {
  companion object {
    // An entry represents the current owner; its queue contains only waiting callers.
    // Registration, handoff, and removal must use the same monitor.
    private val sharedMutexMap = mutableMapOf<String, ArrayDeque<Result>>()
  }

  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "winkk/flutter_native_mutex")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "lock" -> {
        val globalKey = call.argument<String>("globalKey")
        if (globalKey != null) {
          val acquired = synchronized(sharedMutexMap) {
            val waiters = sharedMutexMap[globalKey]
            if (waiters == null) {
              sharedMutexMap[globalKey] = ArrayDeque()
              true
            } else {
              waiters.addLast(result)
              false
            }
          }
          if (acquired) result.success(null)
        } else {
          result.error("Invalid argument", "globalKey is required", null)
        }
      }
      "unlock" -> {
        val globalKey = call.argument<String>("globalKey")
        if (globalKey != null) {
          val (wasLocked, next) = synchronized(sharedMutexMap) {
            val waiters = sharedMutexMap[globalKey]
            if (waiters == null) {
              false to null
            } else {
              val next = waiters.pollFirst()
              if (next == null) sharedMutexMap.remove(globalKey)
              true to next
            }
          }
          // Invoke callbacks outside the monitor so reentrant channel activity is safe.
          if (wasLocked) {
            next?.success(null)
            result.success(null)
          } else {
            result.error("Invalid argument", "mutex must be locked first", null)
          }
        } else {
          result.error("Invalid argument", "globalKey is required", null)
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
