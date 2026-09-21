package com.winkk.flutter_native_mutex

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.Mockito

internal class FlutterNativeMutexPluginTest {
  @Test
  fun unknownMethod_isNotImplemented() {
    val result = Mockito.mock(MethodChannel.Result::class.java)
    FlutterNativeMutexPlugin().onMethodCall(MethodCall("unknown", null), result)
    Mockito.verify(result).notImplemented()
  }

  @Test
  fun missingKey_preservesProtocolError() {
    for (method in listOf("lock", "unlock")) {
      val result = Mockito.mock(MethodChannel.Result::class.java)
      FlutterNativeMutexPlugin().onMethodCall(MethodCall(method, null), result)
      Mockito.verify(result).error("Invalid argument", "globalKey is required", null)
    }
  }

  @Test
  fun unlockingUnknownKey_preservesProtocolError() {
    val result = Mockito.mock(MethodChannel.Result::class.java)
    FlutterNativeMutexPlugin().onMethodCall(MethodCall("unlock", mapOf("globalKey" to "never-locked")), result)
    Mockito.verify(result).error("Invalid argument", "mutex must be locked first", null)
  }

  @Test
  fun detachClearsHandler_andReattachRegistersAgain() {
    val messenger = Mockito.mock(BinaryMessenger::class.java)
    val binding = Mockito.mock(FlutterPlugin.FlutterPluginBinding::class.java)
    Mockito.`when`(binding.binaryMessenger).thenReturn(messenger)
    val plugin = FlutterNativeMutexPlugin()
    plugin.onAttachedToEngine(binding)
    plugin.onDetachedFromEngine(binding)
    Mockito.verify(messenger).setMessageHandler("winkk/flutter_native_mutex", null)
    plugin.onAttachedToEngine(binding)
    Mockito.verify(messenger, Mockito.times(3)).setMessageHandler(Mockito.eq("winkk/flutter_native_mutex"), Mockito.any())
  }
}
