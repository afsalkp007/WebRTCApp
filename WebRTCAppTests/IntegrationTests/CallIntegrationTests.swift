import XCTest
@testable import WebRTCApp

final class CallIntegrationTests: XCTestCase {
    func testEndToEndCallHandshakeBetweenTwoPeers() async throws {
        // Shared in-memory loopback signaling
        let signalingPeerA = MockLoopbackSignalingClient(autoRespondToOffer: false)
        let signalingPeerB = MockLoopbackSignalingClient(autoRespondToOffer: false)

        let webRTCPeerA = SimulatedWebRTCClient()
        let webRTCPeerB = SimulatedWebRTCClient()

        try await signalingPeerA.connect()
        try await signalingPeerB.connect()
        try await webRTCPeerA.start()
        try await webRTCPeerB.start()

        // Cross-wire signaling messages to simulate transport between A and B
        let taskA = Task {
            for await message in signalingPeerA.messageStream {
                switch message {
                case .offer(let offer):
                    try? await webRTCPeerB.set(remoteDescription: offer)
                    if let answer = try? await webRTCPeerB.createAnswer() {
                        try? await signalingPeerB.send(message: .answer(answer))
                        signalingPeerA.simulateIncomingMessage(.answer(answer))
                    }
                case .candidate(let candidate):
                    try? await webRTCPeerB.add(remoteCandidate: candidate)
                default:
                    break
                }
            }
        }

        let taskB = Task {
            for await message in signalingPeerB.messageStream {
                switch message {
                case .candidate(let candidate):
                    try? await webRTCPeerA.add(remoteCandidate: candidate)
                default:
                    break
                }
            }
        }

        // Peer A initiates call
        let offer = try await webRTCPeerA.createOffer()
        try await signalingPeerA.send(message: .offer(offer))

        // Wait for connection handshake to settle
        try await Task.sleep(nanoseconds: 500_000_000)

        // Verify both peers achieved connected state
        XCTAssertEqual(webRTCPeerA.peerConnectionState, .connected)
        XCTAssertEqual(webRTCPeerB.peerConnectionState, .connected)

        // Peer A transmits a message over WebRTC DataChannel
        let sentMessage = try await webRTCPeerA.sendChatMessage("Integration Test Payload", senderId: "Peer-A")
        XCTAssertEqual(sentMessage.text, "Integration Test Payload")

        taskA.cancel()
        taskB.cancel()

        await webRTCPeerA.close()
        await webRTCPeerB.close()
        await signalingPeerA.disconnect()
        await signalingPeerB.disconnect()
    }
}
