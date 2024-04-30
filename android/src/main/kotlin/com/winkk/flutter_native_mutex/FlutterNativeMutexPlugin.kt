package com.winkk.flutter_native_mutex

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

class FlutterNativeMutexPlugin: FlutterPlugin, MethodCallHandler {
  companion object {
    private val sharedMutexMap = ConcurrentHashMap<String, Pair<Mutex, AtomicInteger>>()
    private val scope = CoroutineScope(Dispatchers.Default)
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
          val (mutex, count) = sharedMutexMap.getOrPut(globalKey) { Mutex() to AtomicInteger(0) }
          count.incrementAndGet()
          scope.launch {
            mutex.lock()
            result.success(null)
          }
        } else {
          result.error("Invalid argument", "globalKey is required", null)
        }
      }
      "unlock" -> {
        val globalKey = call.argument<String>("globalKey")
        if (globalKey != null) {
          sharedMutexMap[globalKey]?.let { (mutex, count) ->
            scope.launch {
              mutex.unlock()
              if (count.decrementAndGet() <= 0) {
                sharedMutexMap.remove(globalKey)
              }
              result.success(null)
            }
          } ?: run {
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
