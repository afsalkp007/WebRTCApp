import Foundation

/// Active camera position.
public enum CameraPosition: String, Sendable, CaseIterable {
    case front
    case back

    public var toggled: CameraPosition {
        self == .front ? .back : .front
    }
}

/// User's current local media controls state.
public struct MediaSettings: Sendable, Equatable {
    public var isAudioMuted: Bool
    public var isVideoEnabled: Bool
    public var cameraPosition: CameraPosition
    public var isSpeakerphoneOn: Bool

    public init(
        isAudioMuted: Bool = false,
        isVideoEnabled: Bool = true,
        cameraPosition: CameraPosition = .front,
        isSpeakerphoneOn: Bool = true
    ) {
        self.isAudioMuted = isAudioMuted
        self.isVideoEnabled = isVideoEnabled
        self.cameraPosition = cameraPosition
        self.isSpeakerphoneOn = isSpeakerphoneOn
    }
}
