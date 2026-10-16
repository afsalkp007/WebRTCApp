import Foundation

/// High-fidelity simulated WebRTC client for previews, tests, and standalone demonstrations.
/// Fully implements the WebRTC state machine, candidate gathering, and DataChannel messaging.
public final class SimulatedWebRTCClient: WebRTCClientProtocol, @unchecked Sendable {
    private let lock = NSLock()

    private var _peerConnectionState: PeerConnectionState = .new
    public var peerConnectionState: PeerConnectionState {
        lock.withLock { _peerConnectionState }
    }

    private var _iceConnectionState: IceConnectionState = .new
    public var iceConnectionState: IceConnectionState {
        lock.withLock { _iceConnectionState }
    }

    private var _mediaSettings = MediaSettings()
    public var mediaSettings: MediaSettings {
        lock.withLock { _mediaSettings }
    }

    private var eventContinuation: AsyncStream<WebRTCClientEvent>.Continuation?
    public let eventStream: AsyncStream<WebRTCClientEvent>

    private var statsTask: Task<Void, Never>?
    private let audioSessionManager: AudioSessionManagerProtocol?

    public init(audioSessionManager: AudioSessionManagerProtocol? = nil) {
        self.audioSessionManager = audioSessionManager

        var eContinuation: AsyncStream<WebRTCClientEvent>.Continuation?
        self.eventStream = AsyncStream { continuation in
            eContinuation = continuation
        }
        self.eventContinuation = eContinuation
    }

    deinit {
        statsTask?.cancel()
        eventContinuation?.finish()
    }

    public func start() async throws {
        try? audioSessionManager?.configureAudioSession()
        updatePeerState(.new)
        updateIceState(.new)
    }

    public func createOffer() async throws -> SessionDescription {
        let sdp = """
        v=0
        o=- 3829104829102 2 IN IP4 127.0.0.1
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

        emitEvent(.signalingStateChanged(.haveLocalOffer))

        // Gather simulated local candidate
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 10_000_000)
            let candidate = IceCandidate(
                sdp: "candidate:109283 1 udp 2113937151 192.168.1.150 50001 typ host",
                sdpMLineIndex: 0,
                sdpMid: "0"
            )
            self?.emitEvent(.localCandidateDiscovered(candidate))
        }

        return SessionDescription(type: .offer, sdp: sdp)
    }

    public func createAnswer() async throws -> SessionDescription {
        let sdp = """
        v=0
        o=- 9918273645120 2 IN IP4 127.0.0.1
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

        emitEvent(.signalingStateChanged(.stable))

        // Gather simulated local candidate
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 10_000_000)
            let candidate = IceCandidate(
                sdp: "candidate:551239 1 udp 2113937151 192.168.1.150 50002 typ host",
                sdpMLineIndex: 0,
                sdpMid: "0"
            )
            self?.emitEvent(.localCandidateDiscovered(candidate))
        }

        return SessionDescription(type: .answer, sdp: sdp)
    }

    public func set(remoteDescription: SessionDescription) async throws {
        updatePeerState(.connecting)
        updateIceState(.checking)

        // Handshake settles
        try? await Task.sleep(nanoseconds: 10_000_000)

        updatePeerState(.connected)
        updateIceState(.connected)
        emitEvent(.signalingStateChanged(.stable))
        emitEvent(.dataChannelStateChanged(isOpen: true))
        startStatsReporting()
    }

    public func add(remoteCandidate: IceCandidate) async throws {
        // Successfully absorbed candidate
    }

    public func setAudio(muted: Bool) async {
        lock.withLock {
            _mediaSettings.isAudioMuted = muted
        }
    }

    public func setVideo(enabled: Bool) async {
        lock.withLock {
            _mediaSettings.isVideoEnabled = enabled
        }
    }

    public func switchCamera() async {
        lock.withLock {
            _mediaSettings.cameraPosition = _mediaSettings.cameraPosition.toggled
        }
    }

    public func setSpeakerphone(enabled: Bool) async {
        lock.withLock {
            _mediaSettings.isSpeakerphoneOn = enabled
        }
        try? audioSessionManager?.setSpeakerphone(enabled: enabled)
    }

    public func sendChatMessage(_ text: String, senderId: String) async throws -> ChatMessage {
        guard peerConnectionState == .connected else {
            throw NSError(domain: "SimulatedWebRTCClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "DataChannel is not open"])
        }

        let localMessage = ChatMessage(senderId: senderId, text: text, isLocal: true)

        // Simulate remote peer echoing or answering on DataChannel
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000)
            let remoteMessage = ChatMessage(
                senderId: "Peer-Remote",
                text: "Echo via WebRTC DataChannel: \"\(text)\"",
                isLocal: false
            )
            self?.emitEvent(.dataChannelMessageReceived(remoteMessage))
        }

        return localMessage
    }

    public func close() async {
        statsTask?.cancel()
        statsTask = nil

        updatePeerState(.closed)
        updateIceState(.closed)
        emitEvent(.dataChannelStateChanged(isOpen: false))
        try? audioSessionManager?.deactivateAudioSession()
    }

    private func startStatsReporting() {
        statsTask?.cancel()
        statsTask = Task { [weak self] in
            var bytesSent: UInt64 = 1024
            var bytesReceived: UInt64 = 1024

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { break }

                bytesSent += UInt64.random(in: 120_000...180_000)
                bytesReceived += UInt64.random(in: 120_000...180_000)

                let jitterRtt = Double.random(in: 28.0...54.0)
                let jitterFps = Double.random(in: 29.2...30.1)
                let jitterLoss = Double.random(in: 0.001...0.008)
                let jitterBitrate = Double.random(in: 1100.0...1450.0)

                let stats = ConnectionStats(
                    fps: jitterFps,
                    resolutionWidth: 1280,
                    resolutionHeight: 720,
                    bitrateKbps: jitterBitrate,
                    packetLossRate: jitterLoss,
                    rttMs: jitterRtt,
                    audioCodec: "Opus (48kHz)",
                    videoCodec: "H.264 High Profile",
                    bytesSent: bytesSent,
                    bytesReceived: bytesReceived,
                    timestamp: Date()
                )

                self.emitEvent(.statsUpdated(stats))
            }
        }
    }

    private func updatePeerState(_ state: PeerConnectionState) {
        lock.withLock {
            _peerConnectionState = state
        }
        emitEvent(.peerConnectionStateChanged(state))
    }

    private func updateIceState(_ state: IceConnectionState) {
        lock.withLock {
            _iceConnectionState = state
        }
        emitEvent(.iceConnectionStateChanged(state))
    }

    private func emitEvent(_ event: WebRTCClientEvent) {
        eventContinuation?.yield(event)
    }
}
