import Foundation

/// Represents a Session Description Protocol (SDP) type in WebRTC.
public enum SdpType: String, Codable, Sendable, CaseIterable {
    case offer
    case prAnswer
    case answer
    case rollback
}

/// Encapsulates an SDP offer or answer.
public struct SessionDescription: Codable, Sendable, Equatable {
    public let type: SdpType
    public let sdp: String

    public init(type: SdpType, sdp: String) {
        self.type = type
        self.sdp = sdp
    }
}
