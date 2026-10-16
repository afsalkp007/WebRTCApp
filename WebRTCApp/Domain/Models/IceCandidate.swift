import Foundation

/// Represents an Interactive Connectivity Establishment (ICE) candidate.
public struct IceCandidate: Codable, Sendable, Equatable {
    public let sdp: String
    public let sdpMLineIndex: Int32
    public let sdpMid: String?

    public init(sdp: String, sdpMLineIndex: Int32, sdpMid: String? = nil) {
        self.sdp = sdp
        self.sdpMLineIndex = sdpMLineIndex
        self.sdpMid = sdpMid
    }
}
