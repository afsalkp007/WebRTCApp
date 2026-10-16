import XCTest
@testable import WebRTCApp

@MainActor
final class CallViewModelTests: XCTestCase {
    private var viewModel: CallViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = CallViewModel(
            webRTCClient: SimulatedWebRTCClient(),
            signalingClient: MockLoopbackSignalingClient(autoRespondToOffer: false),
            audioSessionManager: AudioSessionManager()
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    func testInitialStateIsIdle() {
        XCTAssertEqual(viewModel.callState, .idle)
        XCTAssertEqual(viewModel.peerConnectionState, .new)
        XCTAssertFalse(viewModel.mediaSettings.isAudioMuted)
        XCTAssertTrue(viewModel.mediaSettings.isVideoEnabled)
        XCTAssertTrue(viewModel.mediaSettings.isSpeakerphoneOn)
        XCTAssertEqual(viewModel.mediaSettings.cameraPosition, .front)
        XCTAssertTrue(viewModel.chatMessages.isEmpty)
    }

    func testMediaControlToggles() {
        // Audio
        viewModel.toggleMute()
        XCTAssertTrue(viewModel.mediaSettings.isAudioMuted)
        viewModel.toggleMute()
        XCTAssertFalse(viewModel.mediaSettings.isAudioMuted)

        // Video
        viewModel.toggleVideo()
        XCTAssertFalse(viewModel.mediaSettings.isVideoEnabled)
        viewModel.toggleVideo()
        XCTAssertTrue(viewModel.mediaSettings.isVideoEnabled)

        // Camera flip
        viewModel.switchCamera()
        XCTAssertEqual(viewModel.mediaSettings.cameraPosition, .back)
        viewModel.switchCamera()
        XCTAssertEqual(viewModel.mediaSettings.cameraPosition, .front)

        // Speakerphone
        viewModel.toggleSpeakerphone()
        XCTAssertFalse(viewModel.mediaSettings.isSpeakerphoneOn)
        viewModel.toggleSpeakerphone()
        XCTAssertTrue(viewModel.mediaSettings.isSpeakerphoneOn)
    }

    func testStartCallTransitionsState() async {
        viewModel.startCall(asInitiator: true)
        XCTAssertTrue(viewModel.callState.isCallActive)

        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(viewModel.callState.isCallActive)

        viewModel.endCall()
        try? await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertEqual(viewModel.callState, .idle)
    }

    func testSendChatMessageDispatchesWhenTextNonEmpty() async throws {
        viewModel.chatInputText = "Hello Unit Test"
        viewModel.isDataChannelOpen = true

        // Simulate connected state
        try? await Task.sleep(nanoseconds: 10_000_000)
        viewModel.sendChatMessage()

        XCTAssertEqual(viewModel.chatInputText, "")
    }

    func testSheetPresentationStates() {
        XCTAssertFalse(viewModel.isChatPresented)
        viewModel.isChatPresented = true
        XCTAssertTrue(viewModel.isChatPresented)

        XCTAssertFalse(viewModel.isStatsPresented)
        viewModel.isStatsPresented = true
        XCTAssertTrue(viewModel.isStatsPresented)

        XCTAssertFalse(viewModel.isSettingsPresented)
        viewModel.isSettingsPresented = true
        XCTAssertTrue(viewModel.isSettingsPresented)
    }
}
