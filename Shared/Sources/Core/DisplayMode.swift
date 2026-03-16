import AppIntents
import Foundation
import SwiftUI

struct ModeSpectrum: Codable, Hashable, Sendable {
    let warmth: Double
    let redGain: Double
    let greenGain: Double
    let blueCut: Double
    let whitePointBias: Double
    let lowLightBoost: Double
    let prefersDarkSurfaces: Bool
}

enum DisplayMode: String, CaseIterable, Codable, Identifiable, Sendable, AppEnum {
    case skin
    case amber
    case green
    case red
    case black

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "护眼模式")
    static var caseDisplayRepresentations: [DisplayMode: DisplayRepresentation] = [
        .skin: "肉色",
        .amber: "黄色",
        .green: "绿色",
        .red: "红色",
        .black: "黑色"
    ]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .skin: "肉色"
        case .amber: "黄色"
        case .green: "绿色"
        case .red: "红色"
        case .black: "黑色"
        }
    }

    var shortLabel: String {
        switch self {
        case .skin: "推荐"
        case .amber: "小说"
        case .green: "户外"
        case .red: "助眠"
        case .black: "影院"
        }
    }

    var rationale: String {
        switch self {
        case .skin: "最自然的推荐模式，轻暖、轻压白场。"
        case .amber: "暖黄阅读模式，适合小说和长文。"
        case .green: "高环境光友好模式，降低发白刺眼。"
        case .red: "睡前深暖模式，适合夜间低刺激使用。"
        case .black: "极暗压亮模式，适合追剧和游戏。"
        }
    }

    var spectrum: ModeSpectrum {
        switch self {
        case .skin:
            return ModeSpectrum(warmth: 0.18, redGain: 0.12, greenGain: 0.04, blueCut: 0.08, whitePointBias: 0.12, lowLightBoost: 0.05, prefersDarkSurfaces: false)
        case .amber:
            return ModeSpectrum(warmth: 0.48, redGain: 0.22, greenGain: 0.13, blueCut: 0.28, whitePointBias: 0.22, lowLightBoost: 0.08, prefersDarkSurfaces: false)
        case .green:
            return ModeSpectrum(warmth: -0.08, redGain: -0.06, greenGain: 0.26, blueCut: 0.12, whitePointBias: 0.08, lowLightBoost: 0.06, prefersDarkSurfaces: false)
        case .red:
            return ModeSpectrum(warmth: 0.72, redGain: 0.42, greenGain: -0.04, blueCut: 0.54, whitePointBias: 0.28, lowLightBoost: 0.12, prefersDarkSurfaces: true)
        case .black:
            return ModeSpectrum(warmth: 0.04, redGain: 0.02, greenGain: 0.02, blueCut: 0.10, whitePointBias: 0.34, lowLightBoost: 0.30, prefersDarkSurfaces: true)
        }
    }

    var accent: Color {
        switch self {
        case .skin: Color(red: 0.94, green: 0.81, blue: 0.52)
        case .amber: Color(red: 0.96, green: 0.86, blue: 0.28)
        case .green: Color(red: 0.75, green: 0.83, blue: 0.52)
        case .red: Color(red: 0.95, green: 0.62, blue: 0.41)
        case .black: Color(red: 0.47, green: 0.44, blue: 0.35)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.95),
                accent.opacity(0.32),
                Color.black.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
