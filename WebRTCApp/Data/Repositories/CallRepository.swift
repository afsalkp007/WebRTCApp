import Foundation

/// Coordinates the WebRTC lifecycle and signaling protocol between two peers.
public final class CallRepository: @unchecked Sendable {
    private let webRTCClient: WebRTCClientProtocol
    private let signalingClient: SignalingClientProtocol
    private let localPeerId: String

    private var signalingTask: Task<Void, Never>?
    private var webRTCTask: Task<Void, Never>?

    public var webRTC: WebRTCClientProtocol {
        webRTCClient
    }

    public var signaling: SignalingClientProtocol {
        signalingClient
    }

    public init(
        localPeerId: String = "iOS-Peer-\(UUID().uuidString.prefix(6))",
        webRTCClient: WebRTCClientProtocol,
        signalingClient: SignalingClientProtocol
    ) {
        self.localPeerId = localPeerId
        self.webRTCClient = webRTCClient
        self.signalingClient = signalingClient
    }

    deinit {
        signalingTask?.cancel()
        webRTCTask?.cancel()
    }

    public func startCall(asInitiator: Bool, roomId: String) async throws {
        try await webRTCClient.start()
        try await signalingClient.connect()

        listenToSignaling()
        listenToWebRTC()

        try await signalingClient.send(message: .join(roomId: roomId, peerId: localPeerId))

        if asInitiator {
            let offer = try await webRTCClient.createOffer()
            try await signalingClient.send(message: .offer(offer))
        }
    }

    public func endCall() async {
        signalingTask?.cancel()
        signalingTask = nil
        webRTCTask?.cancel()
        webRTCTask = nil

        try? await signalingClient.send(message: .leave(peerId: localPeerId))
        await signalingClient.disconnect()
        await webRTCClient.close()
    }

    private func listenToSignaling() {
        signalingTask?.cancel()
        signalingTask = Task { [weak self] in
            guard let self else { return }

            for await message in self.signalingClient.messageStream {
                guard !Task.isCancelled else { break }

                switch message {
                case .offer(let offer):
                    do {
                        try await self.webRTCClient.set(remoteDescription: offer)
                        let answer = try await self.webRTCClient.createAnswer()
                        try await self.signalingClient.send(message: .answer(answer))
                    } catch {
                        // Handled by webRTC error event
                    }

                case .answer(let answer):
                    try? await self.webRTCClient.set(remoteDescription: answer)

                case .candidate(let candidate):
                    try? await self.webRTCClient.add(remoteCandidate: candidate)

                case .leave:
                    await self.webRTCClient.close()

                case .join, .ping, .pong:
                    break
                }
            }
        }
    }

    private func listenToWebRTC() {
        webRTCTask?.cancel()
        webRTCTask = Task { [weak self] in
            guard let self else { return }

            for await event in self.webRTCClient.eventStream {
                guard !Task.isCancelled else { break }

                switch event {
                case .localCandidateDiscovered(let candidate):
                    try? await self.signalingClient.send(message: .candidate(candidate))
                default:
                    break
                }
            }
        }
    }
}
