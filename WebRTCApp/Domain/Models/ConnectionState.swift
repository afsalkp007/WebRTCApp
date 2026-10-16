import Foundation

/// WebRTC PeerConnection connection state.
public enum PeerConnectionState: String, Sendable, CaseIterable {
    case new = "New"
    case connecting = "Connecting"
    case connected = "Connected"
    case disconnected = "Disconnected"
    case failed = "Failed"
    case closed = "Closed"

    public var isConnected: Bool {
        self == .connected
    }
}

/// WebRTC Signaling state.
public enum SignalingState: String, Sendable, CaseIterable {
    case stable = "Stable"
    case haveLocalOffer = "Have Local Offer"
    case haveRemoteOffer = "Have Remote Offer"
    case haveLocalPrAnswer = "Have Local PrAnswer"
    case haveRemotePrAnswer = "Have Remote PrAnswer"
    case closed = "Closed"
}

/// WebRTC ICE Connection state.
public enum IceConnectionState: String, Sendable, CaseIterable {
    case new = "New"
    case checking = "Checking"
    case connected = "Connected"
    case completed = "Completed"
    case failed = "Failed"
    case disconnected = "Disconnected"
    case closed = "Closed"

    public var isAlive: Bool {
        self == .connected || self == .completed
    }
}

/// Overall Call state represented in the presentation layer.
public enum CallState: Sendable, Equatable {
    case idle
    case joining(roomId: String)
    case ringing
    case connecting
    case connected(peerId: String)
    case failed(String)
    case ended

    public var isCallActive: Bool {
        switch self {
        case .connected, .connecting, .ringing:
            return true
        default:
            return false
        }
    }
}
