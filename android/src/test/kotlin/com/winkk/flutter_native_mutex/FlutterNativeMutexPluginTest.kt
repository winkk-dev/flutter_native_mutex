package com.winkk.flutter_native_mutex

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import org.mockito.Mockito

internal class FlutterNativeMutexPluginTest {
  private class Reply(private val onSuccess: () -> Unit = {}) : MethodChannel.Result {
    val calls = AtomicInteger()
    override fun success(value: Any?) {
      calls.incrementAndGet()
      onSuccess()
    }
    override fun error(code: String, message: String?, details: Any?) {
      throw AssertionError("$code: $message")
    }
    override fun notImplemented() { throw AssertionError("Unexpected method") }
  }

  private fun call(plugin: FlutterNativeMutexPlugin, method: String, key: String, reply: MethodChannel.Result) {
    plugin.onMethodCall(MethodCall(method, mapOf("globalKey" to key)), reply)
  }

  @Test
  fun sameKeyQueuesAcrossPluginInstances_whileDifferentKeysProgress() {
    val first = FlutterNativeMutexPlugin()
    val second = FlutterNativeMutexPlugin()
    val key = UUID.randomUUID().toString()
    val order = mutableListOf<Int>()
    call(first, "lock", key, Reply { order.add(1) })
    call(second, "lock", key, Reply { order.add(2) })
    call(first, "lock", key, Reply { order.add(3) })
    call(second, "lock", "$key-other", Reply { order.add(4) })
    assertEquals(listOf(1, 4), order)
    call(first, "unlock", key, Reply())
    assertEquals(listOf(1, 4, 2), order)
    call(second, "unlock", key, Reply())
    assertEquals(listOf(1, 4, 2, 3), order)
    call(first, "unlock", key, Reply())
    call(second, "unlock", "$key-other", Reply())
    val reused = Reply()
    call(second, "lock", key, reused)
    assertEquals(1, reused.calls.get())
    call(second, "unlock", key, Reply())
  }

  @Test
  fun handoffCallbackCanImmediatelyReleaseAndReacquire() {
    val plugin = FlutterNativeMutexPlugin()
    val key = UUID.randomUUID().toString()
    val reused = Reply()
    call(plugin, "lock", key, Reply())
    val waiting = Reply {
      call(plugin, "unlock", key, Reply())
      call(plugin, "lock", key, reused)
    }
    call(plugin, "lock", key, waiting)
    call(plugin, "unlock", key, Reply())
    assertEquals(1, waiting.calls.get())
    assertEquals(1, reused.calls.get())
    call(plugin, "unlock", key, Reply())
  }

  @Test
  fun concurrentAcquisitionAndFinalReleaseNeverSplitOneKey() {
    val key = UUID.randomUUID().toString()
    val executor = Executors.newFixedThreadPool(8)
    val start = CountDownLatch(1)
    val completed = CountDownLatch(1000)
    val active = AtomicInteger()
    val overlaps = AtomicInteger()
    val failures = AtomicInteger()
    try {
      repeat(1000) {
        executor.submit {
          start.await()
          val plugin = FlutterNativeMutexPlugin()
          call(plugin, "lock", key, object : MethodChannel.Result {
            override fun success(value: Any?) {
              if (active.incrementAndGet() != 1) overlaps.incrementAndGet()
              executor.submit {
                active.decrementAndGet()
                call(plugin, "unlock", key, object : MethodChannel.Result {
                  override fun success(value: Any?) { completed.countDown() }
                  override fun error(code: String, message: String?, details: Any?) {
                    failures.incrementAndGet()
                    completed.countDown()
                  }
                  override fun notImplemented() { failures.incrementAndGet(); completed.countDown() }
                })
              }
            }
            override fun error(code: String, message: String?, details: Any?) {
              failures.incrementAndGet()
              completed.countDown()
            }
            override fun notImplemented() { failures.incrementAndGet(); completed.countDown() }
          })
        }
      }
      start.countDown()
      assertTrue(completed.await(15, TimeUnit.SECONDS), "All lock/unlock calls must complete")
      assertEquals(0, failures.get())
      assertEquals(0, overlaps.get())
      assertEquals(0, active.get())
    } finally {
      executor.shutdownNow()
    }
  }

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
