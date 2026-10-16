import Foundation

/// In-memory loopback signaling client for standalone demonstrations and unit/integration testing.
/// Automatically handles Offer messages and responds with a simulated Answer and ICE candidates.
public final class MockLoopbackSignalingClient: SignalingClientProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _state: SignalingTransportState = .disconnected
    public var state: SignalingTransportState {
        lock.withLock { _state }
    }

    private var stateContinuation: AsyncStream<SignalingTransportState>.Continuation?
    public let stateStream: AsyncStream<SignalingTransportState>

    private var messageContinuation: AsyncStream<SignalingMessage>.Continuation?
    public let messageStream: AsyncStream<SignalingMessage>

    public var autoRespondToOffer: Bool = true
    public var responseDelayNanoseconds: UInt64 = 400_000_000 // 400ms

    public init(autoRespondToOffer: Bool = true) {
        self.autoRespondToOffer = autoRespondToOffer

        var sContinuation: AsyncStream<SignalingTransportState>.Continuation?
        self.stateStream = AsyncStream { continuation in
            sContinuation = continuation
        }
        self.stateContinuation = sContinuation

        var mContinuation: AsyncStream<SignalingMessage>.Continuation?
        self.messageStream = AsyncStream { continuation in
            mContinuation = continuation
        }
        self.messageContinuation = mContinuation
    }

    deinit {
        stateContinuation?.finish()
        messageContinuation?.finish()
    }

    public func connect() async throws {
        updateState(.connecting)
        try? await Task.sleep(nanoseconds: 100_000_000)
        updateState(.connected)
    }

    public func disconnect() async {
        updateState(.disconnected)
    }

    public func send(message: SignalingMessage) async throws {
        guard state == .connected else {
            throw NSError(domain: "MockLoopbackSignalingClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client not connected"])
        }

        switch message {
        case .offer:
            if autoRespondToOffer {
                // Simulate remote peer receiving offer, generating answer and candidates
                Task { [weak self] in
                    guard let self else { return }
                    try? await Task.sleep(nanoseconds: self.responseDelayNanoseconds)

                    let answerSdp = """
                    v=0
                    o=- 8472910385729 2 IN IP4 127.0.0.1
                    s=-
                    t=0 0
                    a=group:BUNDLE 0 1
                    m=audio 9 UDP/TLS/RTP/SAVPF 111
                    c=IN IP4 0.0.0.0
                    a=rtcp:9 IN IP4 0.0.0.0
                    a=sendrecv
                    a=rtpmap:111 opus/48000/2
                    m=video 9 UDP/TLS/RTP/SAVPF 96
                    c=IN IP4 0.0.0.0
                    a=rtcp:9 IN IP4 0.0.0.0
                    a=sendrecv
                    a=rtpmap:96 H264/90000
                    """
                    let answer = SessionDescription(type: .answer, sdp: answerSdp)
                    self.messageContinuation?.yield(.answer(answer))

                    // Emit simulated remote candidate
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    let candidate = IceCandidate(
                        sdp: "candidate:4234901 1 udp 2113937151 192.168.1.100 54123 typ host",
                        sdpMLineIndex: 0,
                        sdpMid: "0"
                    )
                    self.messageContinuation?.yield(.candidate(candidate))
                }
            }

        case .answer, .candidate, .join, .leave, .ping, .pong:
            break
        }
    }

    /// Directly simulate receiving an arbitrary signaling message (useful for tests).
    public func simulateIncomingMessage(_ message: SignalingMessage) {
        messageContinuation?.yield(message)
    }

    private func updateState(_ newState: SignalingTransportState) {
        lock.withLock {
            _state = newState
        }
        stateContinuation?.yield(newState)
    }
}
