import XCTest
@testable import WebRTCApp

final class CallIntegrationTests: XCTestCase {
    func testEndToEndCallHandshakeBetweenTwoPeers() async throws {
        let webRTCPeerA = SimulatedWebRTCClient()
        let webRTCPeerB = SimulatedWebRTCClient()

        try await webRTCPeerA.start()
        try await webRTCPeerB.start()

        // 1. Peer A creates an offer
        let offer = try await webRTCPeerA.createOffer()
        XCTAssertEqual(offer.type, .offer)

        // 2. Offer is signaled to Peer B: Peer B sets remote offer & creates answer
        try await webRTCPeerB.set(remoteDescription: offer)
        let answer = try await webRTCPeerB.createAnswer()
        XCTAssertEqual(answer.type, .answer)

        // 3. Answer is signaled back to Peer A: Peer A sets remote answer
        try await webRTCPeerA.set(remoteDescription: answer)

        // 4. Verify both peers transitioned to connected state
        XCTAssertEqual(webRTCPeerA.peerConnectionState, .connected)
        XCTAssertEqual(webRTCPeerB.peerConnectionState, .connected)
        XCTAssertEqual(webRTCPeerA.iceConnectionState, .connected)
        XCTAssertEqual(webRTCPeerB.iceConnectionState, .connected)

        // 5. Exchange a chat message over WebRTC DataChannel
        let sentMessage = try await webRTCPeerA.sendChatMessage("Integration Test Payload", senderId: "Peer-A")
        XCTAssertEqual(sentMessage.text, "Integration Test Payload")
        XCTAssertTrue(sentMessage.isLocal)

        // 6. Cleanup
        await webRTCPeerA.close()
        await webRTCPeerB.close()
        XCTAssertEqual(webRTCPeerA.peerConnectionState, .closed)
        XCTAssertEqual(webRTCPeerB.peerConnectionState, .closed)
    }

    func testCallRepositoryHandshakeWithLoopbackSignaling() async throws {
        let loopbackSignaling = MockLoopbackSignalingClient(autoRespondToOffer: true)
        loopbackSignaling.responseDelayNanoseconds = 20_000_000 // 20ms

        let webRTCClient = SimulatedWebRTCClient()

        let repository = CallRepository(
            localPeerId: "Integration-Tester",
            webRTCClient: webRTCClient,
            signalingClient: loopbackSignaling
        )

        try await repository.startCall(asInitiator: true, roomId: "integration-room")

        // Wait for loopback response and connection
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(repository.webRTC.peerConnectionState, .connected)
        XCTAssertEqual(repository.webRTC.iceConnectionState, .connected)

        await repository.endCall()
        XCTAssertEqual(repository.webRTC.peerConnectionState, .closed)
    }
}
