import Foundation
import AVFoundation

/// Manages the system audio session for real-time voice and video calls.
public final class AudioSessionManager: AudioSessionManagerProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var isConfigured = false

    public init() {}

    public var currentRoute: AudioOutputRoute {
        lock.withLock {
            #if os(iOS)
            let route = AVAudioSession.sharedInstance().currentRoute
            for output in route.outputs {
                switch output.portType {
                case .builtInSpeaker:
                    return .speaker
                case .builtInReceiver:
                    return .receiver
                case .headphones, .headsetMic:
                    return .headphones
                case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP:
                    return .bluetooth
                default:
                    break
                }
            }
            #endif
            return .speaker
        }
    }

    public func configureAudioSession() throws {
        try lock.withLock {
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .videoChat,
                options: [.allowBluetoothHFP, .allowBluetoothA2DP, .defaultToSpeaker]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            isConfigured = true
            #endif
        }
    }

    public func setSpeakerphone(enabled: Bool) throws {
        try lock.withLock {
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            if enabled {
                try session.overrideOutputAudioPort(.speaker)
            } else {
                try session.overrideOutputAudioPort(.none)
            }
            #endif
        }
    }

    public func deactivateAudioSession() throws {
        try lock.withLock {
            #if os(iOS)
            guard isConfigured else { return }
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            isConfigured = false
            #endif
        }
    }
}
