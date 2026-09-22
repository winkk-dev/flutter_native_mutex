import Flutter
import XCTest

@testable import flutter_native_mutex

final class RunnerTests: XCTestCase {
  private func call(
    _ plugin: FlutterNativeMutexPlugin,
    _ method: String,
    _ key: String,
    result: @escaping FlutterResult = { XCTAssertNil($0) }
  ) {
    plugin.handle(FlutterMethodCall(methodName: method, arguments: ["globalKey": key]), result: result)
  }

  func testUnknownMethodIsNotImplemented() {
    let reply = expectation(description: "Unknown method replies")
    FlutterNativeMutexPlugin().handle(FlutterMethodCall(methodName: "unknown", arguments: nil)) {
      XCTAssertTrue(($0 as AnyObject?) === FlutterMethodNotImplemented)
      reply.fulfill()
    }
    wait(for: [reply], timeout: 1)
  }

  func testMissingKeyPreservesProtocolError() {
    let reply = expectation(description: "Missing keys reply")
    reply.expectedFulfillmentCount = 2
    for method in ["lock", "unlock"] {
      FlutterNativeMutexPlugin().handle(FlutterMethodCall(methodName: method, arguments: nil)) {
        XCTAssertEqual(($0 as? FlutterError)?.code, "Invalid argument")
        XCTAssertEqual(($0 as? FlutterError)?.message, "globalKey is required")
        reply.fulfill()
      }
    }
    wait(for: [reply], timeout: 1)
  }

  func testUnlockingUnknownKeyPreservesProtocolError() {
    let reply = expectation(description: "Unknown key replies")
    call(FlutterNativeMutexPlugin(), "unlock", UUID().uuidString) {
      XCTAssertEqual(($0 as? FlutterError)?.message, "mutex must be locked first")
      reply.fulfill()
    }
    wait(for: [reply], timeout: 1)
  }

  func testSameKeyQueuesAcrossInstancesAndDifferentKeysProgress() {
    let first = FlutterNativeMutexPlugin()
    let second = FlutterNativeMutexPlugin()
    let key = UUID().uuidString
    var order: [Int] = []
    call(first, "lock", key) { _ in order.append(1) }
    call(second, "lock", key) { _ in order.append(2) }
    call(first, "lock", key) { _ in order.append(3) }
    call(second, "lock", key + "-other") { _ in order.append(4) }
    XCTAssertEqual(order, [1, 4])
    call(first, "unlock", key)
    XCTAssertEqual(order, [1, 4, 2])
    call(second, "unlock", key)
    XCTAssertEqual(order, [1, 4, 2, 3])
    call(first, "unlock", key)
    call(second, "unlock", key + "-other")
    call(first, "lock", key) { _ in order.append(5) }
    XCTAssertEqual(order, [1, 4, 2, 3, 5])
    call(first, "unlock", key)
  }

  func testHandoffCallbackCanReleaseAndReacquireWithoutDeadlock() {
    let plugin = FlutterNativeMutexPlugin()
    let key = UUID().uuidString
    var acquired = 0
    call(plugin, "lock", key)
    call(plugin, "lock", key) { _ in
      self.call(plugin, "unlock", key)
      self.call(plugin, "lock", key) { _ in acquired += 1 }
    }
    call(plugin, "unlock", key)
    XCTAssertEqual(acquired, 1)
    call(plugin, "unlock", key)
  }
}
