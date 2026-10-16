import Foundation

/// Audio output route types.
public enum AudioOutputRoute: String, Sendable, CaseIterable {
    case speaker
    case receiver
    case headphones
    case bluetooth
}

/// Interface for managing iOS AVAudioSession for WebRTC voice/video calls.
public protocol AudioSessionManagerProtocol: AnyObject, Sendable {
    func configureAudioSession() throws
    func setSpeakerphone(enabled: Bool) throws
    func deactivateAudioSession() throws
    var currentRoute: AudioOutputRoute { get }
}
