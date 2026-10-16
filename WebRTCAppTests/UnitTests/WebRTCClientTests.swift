import XCTest
@testable import WebRTCApp

final class WebRTCClientTests: XCTestCase {
    func testSimulatedWebRTCClientOfferCreation() async throws {
        let client = SimulatedWebRTCClient()
        try await client.start()

        let offer = try await client.createOffer()
        XCTAssertEqual(offer.type, .offer)
        XCTAssertTrue(offer.sdp.contains("m=video"))
        XCTAssertTrue(offer.sdp.contains("m=audio"))
    }

    func testSimulatedWebRTCClientAnswerCreation() async throws {
        let client = SimulatedWebRTCClient()
        try await client.start()

        let answer = try await client.createAnswer()
        XCTAssertEqual(answer.type, .answer)
        XCTAssertTrue(answer.sdp.contains("m=video"))
    }

    func testMediaControlsToggling() async {
        let client = SimulatedWebRTCClient()

        // Audio
        XCTAssertFalse(client.mediaSettings.isAudioMuted)
        await client.setAudio(muted: true)
        XCTAssertTrue(client.mediaSettings.isAudioMuted)

        // Video
        XCTAssertTrue(client.mediaSettings.isVideoEnabled)
        await client.setVideo(enabled: false)
        XCTAssertFalse(client.mediaSettings.isVideoEnabled)

        // Camera Flip
        XCTAssertEqual(client.mediaSettings.cameraPosition, .front)
        await client.switchCamera()
        XCTAssertEqual(client.mediaSettings.cameraPosition, .back)

        // Speakerphone
        XCTAssertTrue(client.mediaSettings.isSpeakerphoneOn)
        await client.setSpeakerphone(enabled: false)
        XCTAssertFalse(client.mediaSettings.isSpeakerphoneOn)
    }

    func testDataChannelEchoExchange() async throws {
        let client = SimulatedWebRTCClient()
        try await client.start()

        // Set remote description to trigger connection
        let dummySdp = SessionDescription(type: .answer, sdp: "dummy")
        try await client.set(remoteDescription: dummySdp)

        // Wait for connection
        try await Task.sleep(nanoseconds: 30_000_000)
        XCTAssertEqual(client.peerConnectionState, .connected)

        let expectation = expectation(description: "Expected remote echo message")
        var receivedEcho: ChatMessage?

        let task = Task {
            for await event in client.eventStream {
                if case .dataChannelMessageReceived(let message) = event {
                    receivedEcho = message
                    expectation.fulfill()
                    break
                }
            }
        }

        let sent = try await client.sendChatMessage("Ping WebRTC", senderId: "Tester")
        XCTAssertEqual(sent.text, "Ping WebRTC")
        XCTAssertTrue(sent.isLocal)

        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()

        XCTAssertNotNil(receivedEcho)
        XCTAssertFalse(receivedEcho?.isLocal ?? true)
        XCTAssertTrue(receivedEcho?.text.contains("Ping WebRTC") ?? false)

        await client.close()
        XCTAssertEqual(client.peerConnectionState, .closed)
    }
}
