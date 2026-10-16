import Foundation

/// Perceived network and media quality rating.
public enum ConnectionQuality: String, Sendable, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case disconnected = "Disconnected"

    public static func evaluate(rttMs: Double, packetLossRate: Double) -> ConnectionQuality {
        if rttMs <= 0 && packetLossRate <= 0 {
            return .good
        }
        if rttMs < 80 && packetLossRate < 0.02 {
            return .excellent
        } else if rttMs < 180 && packetLossRate < 0.05 {
            return .good
        } else if rttMs < 350 && packetLossRate < 0.12 {
            return .fair
        } else {
            return .poor
        }
    }
}

/// Real-time WebRTC diagnostics and statistics report.
public struct ConnectionStats: Sendable, Equatable {
    public var fps: Double
    public var resolutionWidth: Int
    public var resolutionHeight: Int
    public var bitrateKbps: Double
    public var packetLossRate: Double
    public var rttMs: Double
    public var audioCodec: String
    public var videoCodec: String
    public var bytesSent: UInt64
    public var bytesReceived: UInt64
    public var timestamp: Date

    public var quality: ConnectionQuality {
        ConnectionQuality.evaluate(rttMs: rttMs, packetLossRate: packetLossRate)
    }

    public init(
        fps: Double = 30.0,
        resolutionWidth: Int = 1280,
        resolutionHeight: Int = 720,
        bitrateKbps: Double = 1250.0,
        packetLossRate: Double = 0.005,
        rttMs: Double = 42.0,
        audioCodec: String = "Opus",
        videoCodec: String = "H.264",
        bytesSent: UInt64 = 0,
        bytesReceived: UInt64 = 0,
        timestamp: Date = Date()
    ) {
        self.fps = fps
        self.resolutionWidth = resolutionWidth
        self.resolutionHeight = resolutionHeight
        self.bitrateKbps = bitrateKbps
        self.packetLossRate = packetLossRate
        self.rttMs = rttMs
        self.audioCodec = audioCodec
        self.videoCodec = videoCodec
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
        self.timestamp = timestamp
    }
}
