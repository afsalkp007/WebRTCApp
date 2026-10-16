import XCTest
@testable import WebRTCApp

final class SignalingMessageTests: XCTestCase {
    private var encoder: JSONEncoder!
    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    override func tearDown() {
        encoder = nil
        decoder = nil
        super.tearDown()
    }

    func testEncodeAndDecodeOffer() throws {
        let sdp = "v=0\r\no=- 12345 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0"
        let offer = SessionDescription(type: .offer, sdp: sdp)
        let message = SignalingMessage.offer(offer)

        let data = try encoder.encode(message)
        let decoded = try decoder.decode(SignalingMessage.self, from: data)

        XCTAssertEqual(message, decoded)
    }

    func testEncodeAndDecodeAnswer() throws {
        let sdp = "v=0\r\no=- 67890 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0"
        let answer = SessionDescription(type: .answer, sdp: sdp)
        let message = SignalingMessage.answer(answer)

        let data = try encoder.encode(message)
        let decoded = try decoder.decode(SignalingMessage.self, from: data)

        XCTAssertEqual(message, decoded)
    }

    func testEncodeAndDecodeCandidate() throws {
        let candidate = IceCandidate(
            sdp: "candidate:1 1 UDP 2122260223 192.168.1.1 5000 typ host",
            sdpMLineIndex: 0,
            sdpMid: "audio"
        )
        let message = SignalingMessage.candidate(candidate)

        let data = try encoder.encode(message)
        let decoded = try decoder.decode(SignalingMessage.self, from: data)

        XCTAssertEqual(message, decoded)
    }

    func testEncodeAndDecodeJoinAndLeave() throws {
        let joinMessage = SignalingMessage.join(roomId: "room-abc", peerId: "peer-123")
        let joinData = try encoder.encode(joinMessage)
        let decodedJoin = try decoder.decode(SignalingMessage.self, from: joinData)
        XCTAssertEqual(joinMessage, decodedJoin)

        let leaveMessage = SignalingMessage.leave(peerId: "peer-123")
        let leaveData = try encoder.encode(leaveMessage)
        let decodedLeave = try decoder.decode(SignalingMessage.self, from: leaveData)
        XCTAssertEqual(leaveMessage, decodedLeave)
    }

    func testEncodeAndDecodePingPong() throws {
        let ping = SignalingMessage.ping
        let pong = SignalingMessage.pong

        let pingData = try encoder.encode(ping)
        let pongData = try encoder.encode(pong)

        XCTAssertEqual(try decoder.decode(SignalingMessage.self, from: pingData), .ping)
        XCTAssertEqual(try decoder.decode(SignalingMessage.self, from: pongData), .pong)
    }
}
