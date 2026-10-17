import Foundation

/// Manual signaling client enabling manual copy/paste or QR exchange of SDP and candidates.
public final class ManualSignalingClient: SignalingClientProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _state: SignalingTransportState = .connected
    public var state: SignalingTransportState {
        lock.withLock { _state }
    }

    private var stateContinuation: AsyncStream<SignalingTransportState>.Continuation?
    public let stateStream: AsyncStream<SignalingTransportState>

    private var messageContinuation: AsyncStream<SignalingMessage>.Continuation?
    public let messageStream: AsyncStream<SignalingMessage>

    public var onMessageSent: (@Sendable (SignalingMessage) -> Void)?

    public init() {
        var sContinuation: AsyncStream<SignalingTransportState>.Continuation?
        self.stateStream = AsyncStream { continuation in
            sContinuation = continuation
        }
        self.stateContinuation = sContinuation

        var mContinuation: AsyncStream<SignalingMessage>.Continuation?
        self.messageStream = AsyncStream { continuation in
            mContinuation = continuation
        }
        self.messageContinuation = mContinuation

        sContinuation?.yield(.connected)
    }

    public func connect() async throws {
        // Always connected in manual mode
    }

    public func disconnect() async {
        // No-op for manual
    }

    public func send(message: SignalingMessage) async throws {
        onMessageSent?(message)
    }

    /// Injects manually pasted or scanned signaling message into the stream.
    public func inject(message: SignalingMessage) {
        messageContinuation?.yield(message)
    }
}
