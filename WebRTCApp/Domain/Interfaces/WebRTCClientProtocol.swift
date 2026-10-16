import Foundation

/// Events emitted by WebRTC client implementation.
public enum WebRTCClientEvent: Sendable, Equatable {
    case peerConnectionStateChanged(PeerConnectionState)
    case iceConnectionStateChanged(IceConnectionState)
    case signalingStateChanged(SignalingState)
    case localCandidateDiscovered(IceCandidate)
    case dataChannelStateChanged(isOpen: Bool)
    case dataChannelMessageReceived(ChatMessage)
    case statsUpdated(ConnectionStats)
    case error(String)
}

/// Core interface for WebRTC operations.
public protocol WebRTCClientProtocol: AnyObject, Sendable {
    var peerConnectionState: PeerConnectionState { get }
    var iceConnectionState: IceConnectionState { get }
    var mediaSettings: MediaSettings { get }
    var eventStream: AsyncStream<WebRTCClientEvent> { get }

    // Signaling Handshake
    func createOffer() async throws -> SessionDescription
    func createAnswer() async throws -> SessionDescription
    func set(remoteDescription: SessionDescription) async throws
    func add(remoteCandidate: IceCandidate) async throws

    // Media Controls
    func setAudio(muted: Bool) async
    func setVideo(enabled: Bool) async
    func switchCamera() async
    func setSpeakerphone(enabled: Bool) async

    // Data Channel
    func sendChatMessage(_ text: String, senderId: String) async throws -> ChatMessage

    // Lifecycle
    func start() async throws
    func close() async
}
