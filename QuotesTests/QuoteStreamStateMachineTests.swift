import XCTest
@testable import Quotes

final class QuoteStreamStateMachineTests: XCTestCase {
    func testRecoveryAction_beforeLive_retriesThenFallback() {
        let sut = QuoteStreamStateMachine(maxReconnectAttempts: 2, reconnectDelay: 0.5)

        assertReconnect(sut.recoveryAction(for: "e1"), expectedDelay: 0.5)
        assertReconnect(sut.recoveryAction(for: "e2"), expectedDelay: 0.5)
        assertFallback(sut.recoveryAction(for: "e3"), expectedReason: "e3")
    }

    func testRecoveryAction_afterLive_retriesThenFails() {
        let sut = QuoteStreamStateMachine(maxReconnectAttempts: 2, reconnectDelay: 1.0)
        sut.markLiveDataReceived()

        assertReconnect(sut.recoveryAction(for: "socket"), expectedDelay: 1.0)
        assertReconnect(sut.recoveryAction(for: "socket"), expectedDelay: 1.0)
        assertFailed(sut.recoveryAction(for: "socket"), expectedReason: "socket")
    }

    func testMarkLiveDataReceived_resetsReconnectCounter() {
        let sut = QuoteStreamStateMachine(maxReconnectAttempts: 1, reconnectDelay: 0.2)

        _ = sut.recoveryAction(for: "before-live")
        sut.markLiveDataReceived()

        assertReconnect(sut.recoveryAction(for: "after-live"), expectedDelay: 0.2)
    }
}

private func assertReconnect(_ action: QuoteStreamRecoveryAction, expectedDelay: TimeInterval) {
    guard case let .reconnect(after: delay) = action else {
        return XCTFail("Expected reconnect action")
    }
    XCTAssertEqual(delay, expectedDelay, accuracy: 0.0001)
}

private func assertFallback(_ action: QuoteStreamRecoveryAction, expectedReason: String) {
    guard case let .fallback(reason) = action else {
        return XCTFail("Expected fallback action")
    }
    XCTAssertEqual(reason, expectedReason)
}

private func assertFailed(_ action: QuoteStreamRecoveryAction, expectedReason: String) {
    guard case let .failed(reason) = action else {
        return XCTFail("Expected failed action")
    }
    XCTAssertEqual(reason, expectedReason)
}
