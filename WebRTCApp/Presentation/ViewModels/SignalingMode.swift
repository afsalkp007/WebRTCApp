import Foundation

/// Available signaling modes for WebRTC demonstration.
public enum SignalingMode: String, CaseIterable, Identifiable, Sendable {
    case loopback = "Loopback (Local Demo)"
    case webSocket = "WebSocket Server"
    case manual = "Manual (Air-Gapped SDP)"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .loopback:
            return "Instant 1-device demonstration. Simulated peer automatically responds to offers and echoes data channel chat."
        case .webSocket:
            return "Connects over WebSocket to a real room-based signaling server for multi-device calling."
        case .manual:
            return "Copy and paste SDP Offers, Answers, and ICE candidates directly between devices."
        }
    }
}
