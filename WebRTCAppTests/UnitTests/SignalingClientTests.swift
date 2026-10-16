import XCTest
@testable import WebRTCApp

final class SignalingClientTests: XCTestCase {
    func testLoopbackClientConnectionLifecycle() async throws {
        let client = MockLoopbackSignalingClient(autoRespondToOffer: false)
        XCTAssertEqual(client.state, .disconnected)

        try await client.connect()
        XCTAssertEqual(client.state, .connected)

        await client.disconnect()
        XCTAssertEqual(client.state, .disconnected)
    }

    func testLoopbackClientAutoRespondsToOffer() async throws {
        let client = MockLoopbackSignalingClient(autoRespondToOffer: true)
        client.responseDelayNanoseconds = 10_000_000 // 10ms for fast test execution
        try await client.connect()

        let expectation = expectation(description: "Expected simulated answer and candidate")
        expectation.expectedFulfillmentCount = 2

        var receivedAnswer: SessionDescription?
        var receivedCandidate: IceCandidate?

        let task = Task {
            for await message in client.messageStream {
                switch message {
                case .answer(let answer):
                    receivedAnswer = answer
                    expectation.fulfill()
                case .candidate(let candidate):
                    receivedCandidate = candidate
                    expectation.fulfill()
                default:
                    break
                }
            }
        }

        let offer = SessionDescription(type: .offer, sdp: "dummy-offer-sdp")
        try await client.send(message: .offer(offer))

        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()

        XCTAssertNotNil(receivedAnswer)
        XCTAssertEqual(receivedAnswer?.type, .answer)
        XCTAssertNotNil(receivedCandidate)
    }
}
