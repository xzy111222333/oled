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
    let recipes: [CapabilityBridgeRecipe]
    let actionChecklist: String
    let exportPayload: String
}

struct CapabilityBridgeRecipe: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let recommendedValue: String
    let systemPath: String
    let summary: String
    let steps: [String]
}

struct SystemCapabilityBridgePlanner {
    func plan(profile: DisplayProfile, computation: DisplayComputation) -> CapabilityBridgeSnapshot {
        let whitePoint = Int(computation.whitePointReduction.rounded())
        let tintIntensity = recommendedTintIntensity(profile: profile, computation: computation)
        let tintHue = recommendedTintHue(for: profile.mode)
        let tintSummary = recommendedTintSummary(for: profile.mode)

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

        let recipes = [
            CapabilityBridgeRecipe(
                id: "white_point_recipe",
                title: "白点值桥接",
                recommendedValue: "\(whitePoint)%",
                systemPath: "设置 -> 辅助功能 -> 显示与文字大小 -> 降低白点值",
                summary: "先把硬件亮度锁在安全区，再用降低白点值把主观亮度压下来，这是缓解 OLED 低亮不适最关键的一步。",
                steps: [
                    "打开 设置 -> 辅助功能 -> 显示与文字大小。",
                    "进入“降低白点值”，先打开开关。",
                    "把强度调到 \(whitePoint)%。",
                    "夜间如果仍刺眼，再回到 App 把过滤度提高 10% 左右，重新读取建议值。"
                ]
            ),
            CapabilityBridgeRecipe(
                id: "color_filter_recipe",
                title: "色彩滤镜桥接",
                recommendedValue: tintSummary,
                systemPath: "设置 -> 辅助功能 -> 显示与文字大小 -> 色彩滤镜 -> 色调",
                summary: "颜色模式不是单独一套滤镜，而是同一个过滤强度在不同色偏上的落地。这里给你的是可直接照抄的系统滤镜参数。",
                steps: colorFilterSteps(
                    mode: profile.mode,
                    tintIntensity: tintIntensity,
                    tintHue: tintHue
                )
            ),
            CapabilityBridgeRecipe(
                id: "restore_recipe",
                title: "一键恢复对应动作",
                recommendedValue: "关闭白点值 / 关闭色彩滤镜 / 恢复 App 默认亮度",
                systemPath: "App 首页恢复按钮 + 系统辅助功能开关",
                summary: "恢复时先用 App 恢复亮度，再把系统里的白点值和色彩滤镜关掉，避免残留色偏影响扫码、拍照和识别。",
                steps: [
                    "先点击 App 首页的“恢复原屏”。",
                    "如果你刚才手动开了“降低白点值”，回到系统把它关闭。",
                    "如果你刚才开了“色彩滤镜 -> 色调”，回到系统把“色彩滤镜”关闭。",
                    "以后把“辅助功能快捷键”配置好，就能更快恢复。"
                ]
            )
        ]

        let checklist = """
        OLEDGuard 系统桥接清单

        当前模式：\(profile.mode.title)
        过滤度：\(Int(profile.filterIntensity))%
        建议硬件亮度：\(Int(computation.hardwareBrightness))%
        建议白点值：\(whitePoint)%
        建议色彩滤镜：\(tintSummary)

        白点值路径：
        设置 -> 辅助功能 -> 显示与文字大小 -> 降低白点值

        色彩滤镜路径：
        设置 -> 辅助功能 -> 显示与文字大小 -> 色彩滤镜 -> 色调

        恢复顺序：
        1. App 内点“恢复原屏”
        2. 关闭“降低白点值”
        3. 关闭“色彩滤镜”
        """

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

        return CapabilityBridgeSnapshot(
            items: items,
            recipes: recipes,
            actionChecklist: checklist,
            exportPayload: payload
        )
    }

    private func recommendedTintHue(for mode: DisplayMode) -> Int {
        switch mode {
        case .skin: return 12
        case .amber: return 18
        case .green: return 42
        case .red: return 3
        case .black: return 8
        }
    }

    private func recommendedTintIntensity(profile: DisplayProfile, computation: DisplayComputation) -> Int {
        let base = (profile.filterIntensity * 0.62) + (computation.blueLightReduction * 0.28)
        switch profile.mode {
        case .skin:
            return Int(bridgeClamp(base, to: 16...52).rounded())
        case .amber:
            return Int(bridgeClamp(base + 8, to: 22...78).rounded())
        case .green:
            return Int(bridgeClamp(base + 4, to: 18...72).rounded())
        case .red:
            return Int(bridgeClamp(base + 12, to: 28...88).rounded())
        case .black:
            return Int(bridgeClamp(profile.filterIntensity * 0.24, to: 0...30).rounded())
        }
    }

    private func recommendedTintSummary(for mode: DisplayMode) -> String {
        switch mode {
        case .skin:
            return "色调滤镜，偏自然暖色"
        case .amber:
            return "色调滤镜，暖黄阅读"
        case .green:
            return "色调滤镜，柔和偏绿"
        case .red:
            return "色调滤镜，深暖红助眠"
        case .black:
            return "黑色模式优先压白点值，色调仅作轻微补偿"
        }
    }

    private func colorFilterSteps(
        mode: DisplayMode,
        tintIntensity: Int,
        tintHue: Int
    ) -> [String] {
        var steps = [
            "打开 设置 -> 辅助功能 -> 显示与文字大小。",
            "进入“色彩滤镜”，先打开开关。"
        ]

        switch mode {
        case .black:
            steps.append("黑色模式优先依赖“降低白点值”，色彩滤镜只在仍然刺眼时再开。")
            steps.append("如果要补偿色偏，选择“色调”，把强度调到 \(tintIntensity)%、色相调到 \(tintHue)%。")
        default:
            steps.append("选择“色调”。")
            steps.append("把强度调到 \(tintIntensity)%。")
            steps.append("把色相调到 \(tintHue)%。")
        }

        steps.append("回到 App 对照当前模式，如果过滤度再升高，优先同步提高滤镜强度而不是乱改色相。")
        return steps
    }

    private func bridgeClamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
