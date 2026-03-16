import Foundation

enum BridgeSupportLevel: String, Codable, Sendable {
    case native
    case guided
    case unavailable

    var title: String {
        switch self {
        case .native: "原生可控"
        case .guided: "需系统桥接"
        case .unavailable: "不可公开控制"
        }
    }
}

struct CapabilityBridgeItem: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let supportLevel: BridgeSupportLevel
    let summary: String
    let recommendedAction: String
    let recommendedValue: String?
}

struct CapabilityBridgeSnapshot: Codable, Hashable, Sendable {
    let items: [CapabilityBridgeItem]
    let exportPayload: String
}

struct SystemCapabilityBridgePlanner {
    func plan(profile: DisplayProfile, computation: DisplayComputation) -> CapabilityBridgeSnapshot {
        let items = [
            CapabilityBridgeItem(
                id: "brightness",
                title: "屏幕亮度",
                supportLevel: .native,
                summary: "当前工程已直接控制硬件亮度，用于锁定 PWM 安全区。",
                recommendedAction: "前台即时应用",
                recommendedValue: "\(Int(computation.hardwareBrightness))%"
            ),
            CapabilityBridgeItem(
                id: "white_point",
                title: "降低白点值",
                supportLevel: .guided,
                summary: "需要通过用户配置好的系统辅助功能或快捷动作桥接，无法由公开 API 直接精确写值。",
                recommendedAction: "引导用户创建系统快捷动作",
                recommendedValue: "\(Int(computation.whitePointReduction))%"
            ),
            CapabilityBridgeItem(
                id: "color_filters",
                title: "色彩滤镜",
                supportLevel: .guided,
                summary: "模式色偏应落到系统色彩滤镜或辅助功能快捷入口，适合做一键预设而不是连续拖拽。",
                recommendedAction: "预置阅读黄、助眠红、柔和绿",
                recommendedValue: profile.mode.title
            ),
            CapabilityBridgeItem(
                id: "low_light",
                title: "极暗弱光",
                supportLevel: .guided,
                summary: "适合绑定系统弱光滤镜或缩放低光方案，用于深夜极暗场景。",
                recommendedAction: "作为黑色模式或助眠模式增强项",
                recommendedValue: "\(Int(computation.lowLightBoost))%"
            ),
            CapabilityBridgeItem(
                id: "true_tone",
                title: "原彩显示 / 夜览",
                supportLevel: .unavailable,
                summary: "当前公开能力不适合把它们当核心控制对象，产品应围绕亮度、白点和色彩滤镜构建。",
                recommendedAction: "不作为核心卖点",
                recommendedValue: nil
            )
        ]

        let payload = """
        {
          "mode": "\(profile.mode.rawValue)",
          "filterIntensity": \(Int(profile.filterIntensity)),
          "hardwareBrightness": \(Int(computation.hardwareBrightness)),
          "whitePoint": \(Int(computation.whitePointReduction)),
          "blueLightReduction": \(Int(computation.blueLightReduction)),
          "lowLightBoost": \(Int(computation.lowLightBoost)),
          "prefersDarkSurfaces": \(computation.shouldPreferDarkSurfaces ? "true" : "false")
        }
        """

        return CapabilityBridgeSnapshot(items: items, exportPayload: payload)
    }
}
