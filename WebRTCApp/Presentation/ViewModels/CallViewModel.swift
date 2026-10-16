import SwiftUI
import Observation

/// Main presentation ViewModel coordinating call lifecycle, media controls, and DataChannel messaging.
@Observable
@MainActor
public final class CallViewModel {
    // Call & Connection State
    public var callState: CallState = .idle
    public var peerConnectionState: PeerConnectionState = .new
    public var iceConnectionState: IceConnectionState = .new
    public var signalingState: SignalingState = .stable
    public var connectionStats: ConnectionStats = ConnectionStats()

    // Media Settings
    public var mediaSettings: MediaSettings = MediaSettings()

    // Signaling Settings
    public var signalingMode: SignalingMode = .loopback
    public var roomId: String = "room-101"
    public var serverUrlString: String = "wss://webrtc-signaling-demo.example.com/ws"
    public var localPeerId: String = "iOS-User-\(Int.random(in: 100...999))"

    // Data Channel Chat
    public var chatMessages: [ChatMessage] = []
    public var isDataChannelOpen: Bool = false
    public var chatInputText: String = ""

    // Sheet Presentations
    public var isChatPresented: Bool = false
    public var isStatsPresented: Bool = false
    public var isSettingsPresented: Bool = false
    public var isManualSignalingPresented: Bool = false

    // Manual Signaling Export/Import
    public var manualGeneratedSdp: String = ""
    public var manualGeneratedCandidates: [String] = []
    public var manualImportText: String = ""

    // Error Reporting
    public var errorMessage: String? = nil

    // Internal Services
    private var webRTCClient: WebRTCClientProtocol
    private var signalingClient: SignalingClientProtocol
    private var audioSessionManager: AudioSessionManagerProtocol
    private var callCoordinator: CallRepository?

    @ObservationIgnored
    nonisolated(unsafe) private var eventListeningTask: Task<Void, Never>?
    @ObservationIgnored
    nonisolated(unsafe) private var signalingListeningTask: Task<Void, Never>?

    public init(
        webRTCClient: WebRTCClientProtocol? = nil,
        signalingClient: SignalingClientProtocol? = nil,
        audioSessionManager: AudioSessionManagerProtocol? = nil
    ) {
        let audioMgr = audioSessionManager ?? AudioSessionManager()
        self.audioSessionManager = audioMgr
        self.webRTCClient = webRTCClient ?? SimulatedWebRTCClient(audioSessionManager: audioMgr)
        self.signalingClient = signalingClient ?? MockLoopbackSignalingClient()
    }

    deinit {
        eventListeningTask?.cancel()
        signalingListeningTask?.cancel()
    }

    // MARK: - Call Actions

    public func startCall(asInitiator: Bool = true) {
        guard !callState.isCallActive else { return }

        errorMessage = nil
        callState = .joining(roomId: roomId)

        // Configure signaling client based on mode
        configureClientsForSelectedMode()

        let repository = CallRepository(
            localPeerId: localPeerId,
            webRTCClient: webRTCClient,
            signalingClient: signalingClient
        )
        self.callCoordinator = repository

        startObservingWebRTCEvents()
        startObservingSignalingEvents()

        Task {
            do {
                try await repository.startCall(asInitiator: asInitiator, roomId: roomId)
                callState = .connecting
            } catch {
                callState = .failed(error.localizedDescription)
                errorMessage = error.localizedDescription
            }
        }
    }

    public func endCall() {
        Task {
            await callCoordinator?.endCall()
            callCoordinator = nil
            eventListeningTask?.cancel()
            eventListeningTask = nil
            signalingListeningTask?.cancel()
            signalingListeningTask = nil

            callState = .ended
            peerConnectionState = .closed
            iceConnectionState = .closed
            isDataChannelOpen = false

            try? await Task.sleep(nanoseconds: 10_000_000)
            callState = .idle
        }
    }

    // MARK: - Media Controls

    public func toggleMute() {
        let newMuted = !mediaSettings.isAudioMuted
        mediaSettings.isAudioMuted = newMuted
        Task {
            await webRTCClient.setAudio(muted: newMuted)
        }
    }

    public func toggleVideo() {
        let newVideo = !mediaSettings.isVideoEnabled
        mediaSettings.isVideoEnabled = newVideo
        Task {
            await webRTCClient.setVideo(enabled: newVideo)
        }
    }

    public func switchCamera() {
        mediaSettings.cameraPosition = mediaSettings.cameraPosition.toggled
        Task {
            await webRTCClient.switchCamera()
        }
    }

    public func toggleSpeakerphone() {
        let newSpeaker = !mediaSettings.isSpeakerphoneOn
        mediaSettings.isSpeakerphoneOn = newSpeaker
        Task {
            await webRTCClient.setSpeakerphone(enabled: newSpeaker)
        }
    }

    // MARK: - Data Channel Chat

    public func sendChatMessage() {
        let trimmed = chatInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        chatInputText = ""
        Task {
            do {
                let sentMessage = try await webRTCClient.sendChatMessage(trimmed, senderId: localPeerId)
                chatMessages.append(sentMessage)
            } catch {
                errorMessage = "Failed to send message: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Manual Signaling

    public func applyManualSdpInput() {
        let trimmed = manualImportText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Attempt JSON decode or raw SDP detection
        if let data = trimmed.data(using: .utf8),
           let message = try? JSONDecoder().decode(SignalingMessage.self, from: data) {
            handleManualSignalingMessage(message)
            manualImportText = ""
            return
        }

        // Direct raw SDP offer/answer fallback
        let isOffer = trimmed.contains("m=video") && !trimmed.contains("a=setup:active")
        let sdpType: SdpType = isOffer ? .offer : .answer
        let desc = SessionDescription(type: sdpType, sdp: trimmed)
        handleManualSignalingMessage(isOffer ? .offer(desc) : .answer(desc))
        manualImportText = ""
    }

    private func handleManualSignalingMessage(_ message: SignalingMessage) {
        Task {
            switch message {
            case .offer(let offer):
                do {
                    try await webRTCClient.set(remoteDescription: offer)
                    let answer = try await webRTCClient.createAnswer()
                    if let data = try? JSONEncoder().encode(SignalingMessage.answer(answer)),
                       let str = String(data: data, encoding: .utf8) {
                        manualGeneratedSdp = str
                    }
                } catch {
                    errorMessage = "Error applying offer: \(error.localizedDescription)"
                }

            case .answer(let answer):
                do {
                    try await webRTCClient.set(remoteDescription: answer)
                } catch {
                    errorMessage = "Error applying answer: \(error.localizedDescription)"
                }

            case .candidate(let candidate):
                do {
                    try await webRTCClient.add(remoteCandidate: candidate)
                } catch {
                    errorMessage = "Error adding candidate: \(error.localizedDescription)"
                }

            default:
                break
            }
        }
    }

    // MARK: - Internal Configuration

    private func configureClientsForSelectedMode() {
        switch signalingMode {
        case .loopback:
            self.signalingClient = MockLoopbackSignalingClient(autoRespondToOffer: true)
            self.webRTCClient = SimulatedWebRTCClient(audioSessionManager: audioSessionManager)

        case .webSocket:
            if let url = URL(string: serverUrlString) {
                self.signalingClient = WebSocketSignalingClient(url: url)
            } else {
                self.signalingClient = MockLoopbackSignalingClient(autoRespondToOffer: true)
                self.errorMessage = "Invalid WebSocket URL, fell back to Loopback"
            }
            self.webRTCClient = SimulatedWebRTCClient(audioSessionManager: audioSessionManager)

        case .manual:
            self.signalingClient = ManualSignalingClient()
            self.webRTCClient = SimulatedWebRTCClient(audioSessionManager: audioSessionManager)
        }
    }

    private func startObservingWebRTCEvents() {
        eventListeningTask?.cancel()
        eventListeningTask = Task { [weak self] in
            guard let self else { return }

            for await event in self.webRTCClient.eventStream {
                guard !Task.isCancelled else { break }

                switch event {
                case .peerConnectionStateChanged(let state):
                    self.peerConnectionState = state
                    if state == .connected {
                        self.callState = .connected(peerId: "Remote-Peer")
                    } else if state == .failed {
                        self.callState = .failed("WebRTC connection failed")
                    }

                case .iceConnectionStateChanged(let state):
                    self.iceConnectionState = state

                case .signalingStateChanged(let state):
                    self.signalingState = state

                case .localCandidateDiscovered(let candidate):
                    if let data = try? JSONEncoder().encode(SignalingMessage.candidate(candidate)),
                       let str = String(data: data, encoding: .utf8) {
                        self.manualGeneratedCandidates.append(str)
                    }

                case .dataChannelStateChanged(let isOpen):
                    self.isDataChannelOpen = isOpen

                case .dataChannelMessageReceived(let message):
                    self.chatMessages.append(message)

                case .statsUpdated(let stats):
                    self.connectionStats = stats

                case .error(let msg):
                    self.errorMessage = msg
                }
            }
        }
    }

    private func startObservingSignalingEvents() {
        signalingListeningTask?.cancel()
        signalingListeningTask = Task { [weak self] in
            guard let self else { return }

            for await state in self.signalingClient.stateStream {
                guard !Task.isCancelled else { break }

                if case .error(let err) = state {
                    self.errorMessage = "Signaling error: \(err)"
                }
            }
        }
    }
}
