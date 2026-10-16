import Foundation

/// P2P chat message transmitted over WebRTC DataChannel.
public struct ChatMessage: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let senderId: String
    public let text: String
    public let timestamp: Date
    public let isLocal: Bool

    public init(
        id: UUID = UUID(),
        senderId: String,
        text: String,
        timestamp: Date = Date(),
        isLocal: Bool = true
    ) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
        self.isLocal = isLocal
    }
}
