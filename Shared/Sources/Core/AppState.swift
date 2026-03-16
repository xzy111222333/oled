import Foundation

enum BrightnessStrategy: String, CaseIterable, Codable, Identifiable, Sendable {
    case manual
    case circadian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual: "手动"
        case .circadian: "自动"
        }
    }
}

enum ProtectionRiskLevel: String, Codable, Sendable {
    case low
    case medium
    case high

    var title: String {
        switch self {
        case .low: "低风险"
        case .medium: "中风险"
        case .high: "高风险"
        }
    }
}

enum CircadianPhase: String, Codable, Sendable {
    case daylight
    case evening
    case night
    case sleep

    var label: String {
        switch self {
        case .daylight: "白天"
        case .evening: "傍晚"
        case .night: "夜间"
        case .sleep: "深夜"
        }
    }

    static func resolve(date: Date, calendar: Calendar = .current) -> CircadianPhase {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 7..<18: return CircadianPhase.daylight
        case 18..<22: return CircadianPhase.evening
        case 22..<24: return CircadianPhase.night
        default: return CircadianPhase.sleep
        }
    }
}

struct DisplayProfile: Codable, Hashable, Sendable {
    var mode: DisplayMode
    var filterIntensity: Double
    var visualBrightness: Double
    var brightnessStrategy: BrightnessStrategy
    var pwmProtectionEnabled: Bool
    var autoBrightnessEnabled: Bool
    var circadianFilterEnabled: Bool
    var autoSleepAssistEnabled: Bool

    static let `default` = DisplayProfile(
        mode: .skin,
        filterIntensity: 22,
        visualBrightness: 48,
        brightnessStrategy: .circadian,
        pwmProtectionEnabled: true,
        autoBrightnessEnabled: true,
        circadianFilterEnabled: true,
        autoSleepAssistEnabled: true
    )

    static let restored = DisplayProfile(
        mode: .skin,
        filterIntensity: 0,
        visualBrightness: 55,
        brightnessStrategy: .manual,
        pwmProtectionEnabled: true,
        autoBrightnessEnabled: false,
        circadianFilterEnabled: false,
        autoSleepAssistEnabled: false
    )
}

struct DisplayComputation: Codable, Hashable, Sendable {
    var phase: CircadianPhase
    var hardwareBrightness: Double
    var visualBrightness: Double
    var whitePointReduction: Double
    var colorStrength: Double
    var blueLightReduction: Double
    var lowLightBoost: Double
    var shouldPreferDarkSurfaces: Bool
    var riskLevel: ProtectionRiskLevel
    var comfortScore: Int
    var summary: String

    static let neutral = DisplayComputation(
        phase: .daylight,
        hardwareBrightness: 55,
        visualBrightness: 55,
        whitePointReduction: 0,
        colorStrength: 0,
        blueLightReduction: 0,
        lowLightBoost: 0,
        shouldPreferDarkSurfaces: false,
        riskLevel: .medium,
        comfortScore: 55,
        summary: "原始显示状态"
    )
}

struct AutomationRule: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var isEnabled: Bool
    var hour: Int
    var minute: Int
    var profile: DisplayProfile

    init(
        id: UUID = UUID(),
        title: String,
        isEnabled: Bool,
        hour: Int,
        minute: Int,
        profile: DisplayProfile
    ) {
        self.id = id
        self.title = title
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
        self.profile = profile
    }

    var timeLabel: String {
        String(format: "%02d:%02d", hour, minute)
    }

    func matches(date: Date, calendar: Calendar = .current) -> Bool {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return isEnabled && components.hour == hour && components.minute == minute
    }
}

enum AutomationStarterPack: String, CaseIterable, Identifiable, Sendable {
    case balanced
    case nightOwl
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced: "标准三段"
        case .nightOwl: "重度夜用"
        case .manual: "纯手动"
        }
    }

    var summary: String {
        switch self {
        case .balanced: "傍晚柔和、夜间阅读、早晨恢复，适合大多数人。"
        case .nightOwl: "偏向晚睡人群，夜里更狠地压白场和蓝白刺激。"
        case .manual: "关闭 App 内自动化，只保留手动调节和一键恢复。"
        }
    }

    func rules() -> [AutomationRule] {
        switch self {
        case .balanced:
            return [
                AutomationRule(
                    title: "傍晚柔和",
                    isEnabled: true,
                    hour: 19,
                    minute: 0,
                    profile: DisplayProfile(
                        mode: .skin,
                        filterIntensity: 34,
                        visualBrightness: 52,
                        brightnessStrategy: .circadian,
                        pwmProtectionEnabled: true,
                        autoBrightnessEnabled: true,
                        circadianFilterEnabled: true,
                        autoSleepAssistEnabled: false
                    )
                ),
                AutomationRule(
                    title: "夜间阅读",
                    isEnabled: true,
                    hour: 22,
                    minute: 30,
                    profile: DisplayProfile(
                        mode: .amber,
                        filterIntensity: 62,
                        visualBrightness: 28,
                        brightnessStrategy: .manual,
                        pwmProtectionEnabled: true,
                        autoBrightnessEnabled: false,
                        circadianFilterEnabled: true,
                        autoSleepAssistEnabled: true
                    )
                ),
                AutomationRule(
                    title: "早晨恢复",
                    isEnabled: true,
                    hour: 7,
                    minute: 0,
                    profile: .restored
                )
            ]
        case .nightOwl:
            return [
                AutomationRule(
                    title: "晚间过渡",
                    isEnabled: true,
                    hour: 20,
                    minute: 30,
                    profile: DisplayProfile(
                        mode: .skin,
                        filterIntensity: 42,
                        visualBrightness: 46,
                        brightnessStrategy: .circadian,
                        pwmProtectionEnabled: true,
                        autoBrightnessEnabled: true,
                        circadianFilterEnabled: true,
                        autoSleepAssistEnabled: false
                    )
                ),
                AutomationRule(
                    title: "深夜影院",
                    isEnabled: true,
                    hour: 23,
                    minute: 30,
                    profile: DisplayProfile(
                        mode: .black,
                        filterIntensity: 78,
                        visualBrightness: 22,
                        brightnessStrategy: .manual,
                        pwmProtectionEnabled: true,
                        autoBrightnessEnabled: false,
                        circadianFilterEnabled: false,
                        autoSleepAssistEnabled: true
                    )
                ),
                AutomationRule(
                    title: "起床恢复",
                    isEnabled: true,
                    hour: 8,
                    minute: 30,
                    profile: .restored
                )
            ]
        case .manual:
            return [
                AutomationRule(
                    title: "傍晚柔和",
                    isEnabled: false,
                    hour: 19,
                    minute: 0,
                    profile: DisplayProfile(
                        mode: .skin,
                        filterIntensity: 34,
                        visualBrightness: 52,
                        brightnessStrategy: .circadian,
                        pwmProtectionEnabled: true,
                        autoBrightnessEnabled: true,
                        circadianFilterEnabled: true,
                        autoSleepAssistEnabled: false
                    )
                ),
                AutomationRule(
                    title: "夜间阅读",
                    isEnabled: false,
                    hour: 22,
                    minute: 30,
                    profile: DisplayProfile(
                        mode: .amber,
                        filterIntensity: 62,
                        visualBrightness: 28,
                        brightnessStrategy: .manual,
                        pwmProtectionEnabled: true,
                        autoBrightnessEnabled: false,
                        circadianFilterEnabled: true,
                        autoSleepAssistEnabled: true
                    )
                ),
                AutomationRule(
                    title: "早晨恢复",
                    isEnabled: false,
                    hour: 7,
                    minute: 0,
                    profile: .restored
                )
            ]
        }
    }
}

enum CalibrationQuickAction: String, CaseIterable, Identifiable, Sendable {
    case reduceGlare
    case strongerProtection
    case reduceColorCast
    case extremeNight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reduceGlare: "还是刺眼"
        case .strongerProtection: "继续护眼"
        case .reduceColorCast: "颜色太重"
        case .extremeNight: "极暗舒缓"
        }
    }

    var summary: String {
        switch self {
        case .reduceGlare: "提高过滤度，轻压视觉亮度，让白场别那么冲。"
        case .strongerProtection: "把当前方案往夜间舒适区再推一步。"
        case .reduceColorCast: "保留护眼但减少偏色，适合觉得太黄太红时。"
        case .extremeNight: "快速切到深夜可用的低刺激状态。"
        }
    }

    func applying(to profile: DisplayProfile, phase: CircadianPhase) -> DisplayProfile {
        var adjusted = profile

        switch self {
        case .reduceGlare:
            adjusted.filterIntensity = min(profile.filterIntensity + 10, 100)
            adjusted.visualBrightness = max(profile.visualBrightness - 8, 16)
            adjusted.pwmProtectionEnabled = true
        case .strongerProtection:
            adjusted.filterIntensity = min(profile.filterIntensity + 16, 100)
            adjusted.visualBrightness = max(profile.visualBrightness - 6, 18)
            adjusted.pwmProtectionEnabled = true
            adjusted.autoSleepAssistEnabled = phase == .night || phase == .sleep
            if phase == .night && profile.mode == .skin {
                adjusted.mode = .amber
            }
            if phase == .sleep && profile.mode != .red && profile.mode != .black {
                adjusted.mode = .red
            }
        case .reduceColorCast:
            adjusted.filterIntensity = max(profile.filterIntensity - 12, 0)
            adjusted.visualBrightness = min(profile.visualBrightness + 6, 70)
            adjusted.autoBrightnessEnabled = phase == .daylight || phase == .evening
            adjusted.brightnessStrategy = adjusted.autoBrightnessEnabled ? .circadian : profile.brightnessStrategy
            if profile.mode == .red || profile.mode == .green || profile.mode == .black {
                adjusted.mode = phase == .sleep ? .amber : .skin
            }
        case .extremeNight:
            adjusted.mode = phase == .sleep ? .red : .black
            adjusted.filterIntensity = max(profile.filterIntensity, 76)
            adjusted.visualBrightness = min(profile.visualBrightness, 22)
            adjusted.pwmProtectionEnabled = true
            adjusted.autoBrightnessEnabled = false
            adjusted.brightnessStrategy = .manual
            adjusted.circadianFilterEnabled = true
            adjusted.autoSleepAssistEnabled = true
        }

        return adjusted
    }
}

struct AppState: Codable, Sendable {
    var activeProfile: DisplayProfile
    var lastComputation: DisplayComputation
    var automationRules: [AutomationRule]
    var isProtectionEnabled: Bool
    var hasCompletedOnboarding: Bool
    var baselineBrightness: Double?
    var todayUsageMinutes: Int
    var fatigueUsageMinutes: Int
    var lastMutation: Date

    static let `default` = AppState(
        activeProfile: .default,
        lastComputation: .neutral,
        automationRules: AutomationStarterPack.balanced.rules(),
        isProtectionEnabled: true,
        hasCompletedOnboarding: true,
        baselineBrightness: nil,
        todayUsageMinutes: 0,
        fatigueUsageMinutes: 0,
        lastMutation: .now
    )
}
