import Foundation

/// Discriminated union of WebRTC signaling messages exchanged over a signaling transport.
public enum SignalingMessage: Codable, Sendable, Equatable {
    case join(roomId: String, peerId: String)
    case offer(SessionDescription)
    case answer(SessionDescription)
    case candidate(IceCandidate)
    case leave(peerId: String)
    case ping
    case pong

    private enum CodingKeys: String, CodingKey {
        case type
        case payload
        case roomId
        case peerId
    }

    private enum MessageType: String, Codable {
        case join
        case offer
        case answer
        case candidate
        case leave
        case ping
        case pong
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)

        switch type {
        case .join:
            let roomId = try container.decode(String.self, forKey: .roomId)
            let peerId = try container.decode(String.self, forKey: .peerId)
            self = .join(roomId: roomId, peerId: peerId)
        case .offer:
            let description = try container.decode(SessionDescription.self, forKey: .payload)
            self = .offer(description)
        case .answer:
            let description = try container.decode(SessionDescription.self, forKey: .payload)
            self = .answer(description)
        case .candidate:
            let candidate = try container.decode(IceCandidate.self, forKey: .payload)
            self = .candidate(candidate)
        case .leave:
            let peerId = try container.decode(String.self, forKey: .peerId)
            self = .leave(peerId: peerId)
        case .ping:
            self = .ping
        case .pong:
            self = .pong
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .join(let roomId, let peerId):
            try container.encode(MessageType.join, forKey: .type)
            try container.encode(roomId, forKey: .roomId)
            try container.encode(peerId, forKey: .peerId)
        case .offer(let description):
            try container.encode(MessageType.offer, forKey: .type)
            try container.encode(description, forKey: .payload)
        case .answer(let description):
            try container.encode(MessageType.answer, forKey: .type)
            try container.encode(description, forKey: .payload)
        case .candidate(let candidate):
            try container.encode(MessageType.candidate, forKey: .type)
            try container.encode(candidate, forKey: .payload)
        case .leave(let peerId):
            try container.encode(MessageType.leave, forKey: .type)
            try container.encode(peerId, forKey: .peerId)
        case .ping:
            try container.encode(MessageType.ping, forKey: .type)
        case .pong:
            try container.encode(MessageType.pong, forKey: .type)
        }
    }
}
