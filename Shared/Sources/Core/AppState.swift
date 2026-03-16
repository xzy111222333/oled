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
        case 7..<18: .daylight
        case 18..<22: .evening
        case 22..<24: .night
        default: .sleep
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
        automationRules: [
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
                title: "深夜助眠",
                isEnabled: true,
                hour: 0,
                minute: 0,
                profile: DisplayProfile(
                    mode: .red,
                    filterIntensity: 84,
                    visualBrightness: 18,
                    brightnessStrategy: .manual,
                    pwmProtectionEnabled: true,
                    autoBrightnessEnabled: false,
                    circadianFilterEnabled: true,
                    autoSleepAssistEnabled: true
                )
            )
        ],
        isProtectionEnabled: true,
        hasCompletedOnboarding: false,
        baselineBrightness: nil,
        todayUsageMinutes: 0,
        fatigueUsageMinutes: 0,
        lastMutation: .now
    )
}
