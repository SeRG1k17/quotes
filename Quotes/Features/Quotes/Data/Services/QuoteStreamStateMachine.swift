//
//  QuoteStreamStateMachine.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import Foundation

enum QuoteStreamRecoveryAction {
    case reconnect(after: TimeInterval)
    case fallback(reason: String)
    case failed(reason: String)
}

protocol QuoteStreamStateMachining: AnyObject {
    var hasReceivedLiveData: Bool { get }

    func reset()
    func markLiveDataReceived()
    func recoveryAction(for reason: String) -> QuoteStreamRecoveryAction
}

final class QuoteStreamStateMachine: QuoteStreamStateMachining {
    private let maxReconnectAttempts: Int
    private let reconnectDelay: TimeInterval

    private(set) var hasReceivedLiveData = false
    private var reconnectAttempt = 0

    init(maxReconnectAttempts: Int, reconnectDelay: TimeInterval) {
        self.maxReconnectAttempts = maxReconnectAttempts
        self.reconnectDelay = reconnectDelay
    }

    func reset() {
        hasReceivedLiveData = false
        reconnectAttempt = 0
    }

    func markLiveDataReceived() {
        hasReceivedLiveData = true
        reconnectAttempt = 0
    }

    func recoveryAction(for reason: String) -> QuoteStreamRecoveryAction {
        guard reconnectAttempt < maxReconnectAttempts else {
            if hasReceivedLiveData {
                return .failed(reason: reason)
            }
            return .fallback(reason: reason)
        }

        reconnectAttempt += 1
        return .reconnect(after: reconnectDelay)
    }
}
