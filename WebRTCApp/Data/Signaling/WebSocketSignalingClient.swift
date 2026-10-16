import Foundation

/// WebSocket-based signaling transport connecting to a WebRTC signaling server.
public final class WebSocketSignalingClient: SignalingClientProtocol, @unchecked Sendable {
    private let url: URL
    private let session: URLSession
    private var webSocketTask: URLSessionWebSocketTask?
    private let lock = NSLock()

    private var _state: SignalingTransportState = .disconnected
    public var state: SignalingTransportState {
        lock.withLock { _state }
    }

    private var stateContinuation: AsyncStream<SignalingTransportState>.Continuation?
    public let stateStream: AsyncStream<SignalingTransportState>

    private var messageContinuation: AsyncStream<SignalingMessage>.Continuation?
    public let messageStream: AsyncStream<SignalingMessage>

    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private var pingTask: Task<Void, Never>?

    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder

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
    }

    deinit {
        pingTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        stateContinuation?.finish()
        messageContinuation?.finish()
    }

    public func connect() async throws {
        updateState(.connecting)

        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()

        updateState(.connected)
        startListening(task: task)
        startHeartbeat()
    }

    public func disconnect() async {
        pingTask?.cancel()
        pingTask = nil

        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil

        updateState(.disconnected)
    }

    public func send(message: SignalingMessage) async throws {
        guard let task = webSocketTask else {
            throw NSError(domain: "WebSocketSignalingClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebSocket is not connected"])
        }

        let data = try jsonEncoder.encode(message)
        guard let text = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "WebSocketSignalingClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode message to string"])
        }

        try await task.send(.string(text))
    }

    private func startListening(task: URLSessionWebSocketTask) {
        Task { [weak self, weak task] in
            guard let self, let task else { return }

            while task.state == .running {
                do {
                    let wsMessage = try await task.receive()
                    let messageData: Data

                    switch wsMessage {
                    case .string(let text):
                        messageData = Data(text.utf8)
                    case .data(let data):
                        messageData = data
                    @unknown default:
                        continue
                    }

                    if let signalingMessage = try? self.jsonDecoder.decode(SignalingMessage.self, from: messageData) {
                        self.messageContinuation?.yield(signalingMessage)
                    }
                } catch {
                    if task.state == .running {
                        self.updateState(.error(error.localizedDescription))
                    }
                    break
                }
            }
        }
    }

    private func startHeartbeat() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                guard let self, let task = self.webSocketTask else { break }
                task.sendPing { error in
                    if let error {
                        self.updateState(.error("Ping failed: \(error.localizedDescription)"))
                    }
                }
            }
        }
    }

    private func updateState(_ newState: SignalingTransportState) {
        lock.withLock {
            _state = newState
        }
        stateContinuation?.yield(newState)
    }
}
