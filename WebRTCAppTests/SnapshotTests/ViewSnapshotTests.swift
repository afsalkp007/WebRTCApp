import XCTest
import SwiftUI
@testable import WebRTCApp

@MainActor
final class ViewSnapshotTests: XCTestCase {
    func testMainCallViewRendersInLightModePortrait() {
        let viewModel = CallViewModel()
        let view = MainCallView(viewModel: viewModel)
            .preferredColorScheme(.light)

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852) // iPhone 15 Pro portrait
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
        XCTAssertEqual(controller.view.frame.width, 393)
        XCTAssertEqual(controller.view.frame.height, 852)
    }

    func testMainCallViewRendersInDarkModeLandscape() {
        let viewModel = CallViewModel()
        viewModel.callState = .connected(peerId: "Remote-Peer-42")
        viewModel.isDataChannelOpen = true

        let view = MainCallView(viewModel: viewModel)
            .preferredColorScheme(.dark)

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 852, height: 393) // Landscape
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
        XCTAssertEqual(controller.view.frame.width, 852)
        XCTAssertEqual(controller.view.frame.height, 393)
    }

    func testCallControlsBarRendersWithDynamicTypeAccessibilityScale() {
        let view = CallControlsBar(
            isCallActive: true,
            isAudioMuted: false,
            isVideoEnabled: true,
            isSpeakerphoneOn: true,
            isDataChannelOpen: true,
            unreadMessageCount: 3,
            onToggleAudio: {},
            onToggleVideo: {},
            onSwitchCamera: {},
            onToggleSpeaker: {},
            onToggleCall: {},
            onOpenChat: {},
            onOpenStats: {}
        )
        .environment(\.dynamicTypeSize, .accessibility3)

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 120)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
    }

    func testQualityBadgeRendersAccurately() {
        let view = QualityBadgeView(
            quality: .excellent,
            rttMs: 38.0,
            packetLossRate: 0.002
        )

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 250, height: 44)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
    }

    func testDataChannelChatSheetRenders() {
        let messages = [
            ChatMessage(senderId: "Peer-A", text: "Hello WebRTC", isLocal: true),
            ChatMessage(senderId: "Peer-B", text: "Echo: Hello WebRTC", isLocal: false)
        ]

        let view = DataChannelChatSheet(
            messages: .constant(messages),
            isDataChannelOpen: true,
            onSendMessage: { _ in },
            onClose: {}
        )

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
    }

    func testStatsOverlayViewRenders() {
        let stats = ConnectionStats(
            fps: 30.0,
            resolutionWidth: 1280,
            resolutionHeight: 720,
            bitrateKbps: 1240.0,
            packetLossRate: 0.003,
            rttMs: 42.0
        )

        let view = StatsOverlayView(
            stats: stats,
            peerConnectionState: .connected,
            iceConnectionState: .connected,
            signalingState: .stable,
            onClose: {}
        )

        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        controller.view.layoutIfNeeded()

        XCTAssertNotNil(controller.view)
    }
}
