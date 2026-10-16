import Foundation

/// Defines signaling transport state.
public enum SignalingTransportState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

/// Protocol abstracting the signaling mechanism (WebSocket, Loopback, Manual).
public protocol SignalingClientProtocol: AnyObject, Sendable {
    var state: SignalingTransportState { get }
    var stateStream: AsyncStream<SignalingTransportState> { get }
    var messageStream: AsyncStream<SignalingMessage> { get }

    func connect() async throws
    func disconnect() async
    func send(message: SignalingMessage) async throws
}
