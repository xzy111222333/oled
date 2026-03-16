import Foundation
import SwiftUI
import WidgetKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var state: AppState

    private let store: SharedStore
    private let engine: DisplayTuningEngine
    private let bridgePlanner: SystemCapabilityBridgePlanner
    private let displayController: SystemDisplayController
    private var lastSyncedMutation: Date
    private var sessionStart: Date?
    private var automationTask: Task<Void, Never>?

    init(
        store: SharedStore = SharedStore(),
        engine: DisplayTuningEngine = DisplayTuningEngine(),
        bridgePlanner: SystemCapabilityBridgePlanner = SystemCapabilityBridgePlanner(),
        displayController: SystemDisplayController? = nil
    ) {
        let loaded = store.load()
        self.state = loaded
        self.store = store
        self.engine = engine
        self.bridgePlanner = bridgePlanner
        self.displayController = displayController ?? SystemDisplayController()
        self.lastSyncedMutation = loaded.lastMutation
        self.displayController.captureBaselineIfNeeded(from: &self.state)
        persist()
        applyCurrentProfile()
    }

    var activeProfile: DisplayProfile { state.activeProfile }
    var computation: DisplayComputation { state.lastComputation }
    var automationRules: [AutomationRule] { state.automationRules }
    var todayUsageMinutes: Int { state.todayUsageMinutes }
    var fatigueUsageMinutes: Int { state.fatigueUsageMinutes }
    var bridgeSnapshot: CapabilityBridgeSnapshot {
        bridgePlanner.plan(profile: state.activeProfile, computation: state.lastComputation)
    }
    var intensityBand: FilterIntensityBand {
        FilterIntensityBand.resolve(for: state.activeProfile.filterIntensity)
    }
    var protectionStatusTitle: String {
        state.isProtectionEnabled ? "护眼已开启" : "当前为原屏状态"
    }
    var protectionStatusDetail: String {
        state.isProtectionEnabled ? computation.summary : "点击任意预设或调节滑块即可重新进入护眼状态。"
    }
    var automationSummary: String {
        let enabledCount = automationRules.filter(\.isEnabled).count
        guard enabledCount > 0 else { return "自动化未开启，当前以手动调节为主。" }
        if let next = nextEnabledRuleDescription() {
            return "已启用 \(enabledCount) 条自动化规则，下一次触发：\(next)"
        }
        return "已启用 \(enabledCount) 条自动化规则，等待进入对应时间段。"
    }
    var comfortHeadline: String {
        switch computation.riskLevel {
        case .low:
            return "当前方案偏稳定，适合继续使用。"
        case .medium:
            return "还有优化空间，建议继续压白场或提高过滤度。"
        case .high:
            return "当前亮度区间偏敏感，建议开启安全保护或切换夜间预设。"
        }
    }
    var recommendedPresets: [DisplayPreset] {
        DisplayPreset.recommended(for: computation.phase)
    }
    var recommendedAutomationPack: AutomationStarterPack {
        switch computation.phase {
        case .daylight, .evening:
            return .balanced
        case .night, .sleep:
            return .nightOwl
        }
    }
    var automationPackSummary: String {
        nextEnabledRuleDescription().map { "下一次触发：\($0)" } ?? "暂时没有可触发的自动化。"
    }

    func setMode(_ mode: DisplayMode) {
        state.activeProfile.mode = mode
        state.isProtectionEnabled = true
        applyCurrentProfile()
    }

    func setFilterIntensity(_ value: Double) {
        state.activeProfile.filterIntensity = value
        state.isProtectionEnabled = value > 0
        applyCurrentProfile()
    }

    func setVisualBrightness(_ value: Double) {
        state.activeProfile.visualBrightness = value
        applyCurrentProfile()
    }

    func setBrightnessStrategy(_ strategy: BrightnessStrategy) {
        state.activeProfile.brightnessStrategy = strategy
        state.activeProfile.autoBrightnessEnabled = strategy == .circadian
        applyCurrentProfile()
    }

    func setPWMProtectionEnabled(_ isEnabled: Bool) {
        state.activeProfile.pwmProtectionEnabled = isEnabled
        applyCurrentProfile()
    }

    func setAutoBrightnessEnabled(_ isEnabled: Bool) {
        state.activeProfile.autoBrightnessEnabled = isEnabled
        state.activeProfile.brightnessStrategy = isEnabled ? .circadian : .manual
        applyCurrentProfile()
    }

    func setCircadianFilterEnabled(_ isEnabled: Bool) {
        state.activeProfile.circadianFilterEnabled = isEnabled
        if isEnabled {
            state.activeProfile.brightnessStrategy = .circadian
        }
        applyCurrentProfile()
    }

    func setAutoSleepAssistEnabled(_ isEnabled: Bool) {
        state.activeProfile.autoSleepAssistEnabled = isEnabled
        if isEnabled && state.activeProfile.filterIntensity < 45 {
            state.activeProfile.filterIntensity = 45
        }
        applyCurrentProfile()
    }

    func toggleProtection() {
        state.isProtectionEnabled.toggle()
        applyCurrentProfile()
    }

    func restoreDisplay() {
        state.isProtectionEnabled = false
        state.activeProfile = .restored
        state.lastComputation = .neutral
        displayController.restore(using: state)
        persist()
    }

    func markOnboardingComplete() {
        state.hasCompletedOnboarding = true
        persist()
    }

    func toggleRule(_ ruleID: UUID, isEnabled: Bool) {
        guard let index = state.automationRules.firstIndex(where: { $0.id == ruleID }) else { return }
        state.automationRules[index].isEnabled = isEnabled
        persist()
    }

    func updateRuleTime(_ ruleID: UUID, date: Date) {
        guard let index = state.automationRules.firstIndex(where: { $0.id == ruleID }) else { return }
        let calendar = Calendar.current
        state.automationRules[index].hour = calendar.component(.hour, from: date)
        state.automationRules[index].minute = calendar.component(.minute, from: date)
        persist()
    }

    func applyRule(_ rule: AutomationRule) {
        state.activeProfile = rule.profile
        state.isProtectionEnabled = rule.profile.filterIntensity > 0
        applyCurrentProfile()
    }

    func applyPreset(_ preset: DisplayPreset) {
        state.activeProfile = preset.profile
        state.isProtectionEnabled = preset.profile.filterIntensity > 0
        applyCurrentProfile()
    }

    func applyCalibrationAction(_ action: CalibrationQuickAction) {
        state.activeProfile = action.applying(to: state.activeProfile, phase: state.lastComputation.phase)
        state.isProtectionEnabled = state.activeProfile.filterIntensity > 0
        applyCurrentProfile()
    }

    func applyAutomationStarterPack(_ pack: AutomationStarterPack) {
        state.automationRules = pack.rules()
        persist()
    }

    func syncIfNeededFromSharedStore() {
        let latest = store.load()
        guard latest.lastMutation > lastSyncedMutation else { return }
        state = latest
        lastSyncedMutation = latest.lastMutation
        if state.isProtectionEnabled {
            applyCurrentProfile()
        } else {
            displayController.restore(using: state)
        }
    }

    func applyDueAutomations(now: Date = .now) {
        guard let dueRule = state.automationRules.first(where: { $0.matches(date: now) }) else { return }
        applyRule(dueRule)
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            sessionStart = .now
            syncIfNeededFromSharedStore()
            applyDueAutomations()
            startAutomationLoopIfNeeded()
        case .inactive, .background:
            automationTask?.cancel()
            automationTask = nil
            flushSessionIfNeeded()
        @unknown default:
            break
        }
    }

    func recommendationBannerText(now: Date = .now) -> String {
        switch CircadianPhase.resolve(date: now) {
        case .daylight:
            return "白天建议保持低过滤度，主打自然和清晰。"
        case .evening:
            return "傍晚适合提高过滤度，逐步过渡到柔和色调。"
        case .night:
            return "夜间优先压白场和蓝白刺激，避免低亮频闪不适。"
        case .sleep:
            return "深夜建议红色或黑色模式，配合高过滤度和较低视觉亮度。"
        }
    }

    private func applyCurrentProfile() {
        let computation = state.isProtectionEnabled ? engine.compute(profile: state.activeProfile) : .neutral
        state.lastComputation = computation
        if state.isProtectionEnabled {
            displayController.apply(computation: computation)
        } else {
            displayController.restore(using: state)
        }
        persist()
    }

    private func persist() {
        state.lastMutation = .now
        lastSyncedMutation = state.lastMutation
        store.save(state)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func flushSessionIfNeeded() {
        guard let sessionStart else { return }
        let elapsed = Int(Date().timeIntervalSince(sessionStart) / 60)
        guard elapsed > 0 else {
            self.sessionStart = nil
            return
        }

        state.todayUsageMinutes += elapsed
        if state.lastComputation.riskLevel != .low {
        state.fatigueUsageMinutes += elapsed
        }
        self.sessionStart = nil
        persist()
    }

    private func nextEnabledRuleDescription(now: Date = .now) -> String? {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        let nextRule = automationRules
            .filter(\.isEnabled)
            .sorted {
                if $0.hour == $1.hour { return $0.minute < $1.minute }
                return $0.hour < $1.hour
            }
            .first {
                ($0.hour > currentHour) || ($0.hour == currentHour && $0.minute >= currentMinute)
            }
            ?? automationRules.filter(\.isEnabled).sorted {
                if $0.hour == $1.hour { return $0.minute < $1.minute }
                return $0.hour < $1.hour
            }.first

        guard let nextRule else { return nil }
        return "\(nextRule.title) · \(nextRule.timeLabel)"
    }

    private func startAutomationLoopIfNeeded() {
        guard automationTask == nil else { return }
        automationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard let self else { return }
                self.syncIfNeededFromSharedStore()
                self.applyDueAutomations()
            }
        }
    }
}

struct DisplayPreset: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let profile: DisplayProfile

    static func recommended(for phase: CircadianPhase) -> [DisplayPreset] {
        let presets = [
            DisplayPreset(
                id: "daily",
                title: "日常柔和",
                subtitle: "自然常开",
                icon: "sun.max.fill",
                profile: DisplayProfile(
                    mode: .skin,
                    filterIntensity: 24,
                    visualBrightness: 56,
                    brightnessStrategy: .circadian,
                    pwmProtectionEnabled: true,
                    autoBrightnessEnabled: true,
                    circadianFilterEnabled: true,
                    autoSleepAssistEnabled: false
                )
            ),
            DisplayPreset(
                id: "reading",
                title: "阅读护眼",
                subtitle: "暖黄降刺激",
                icon: "book.fill",
                profile: DisplayProfile(
                    mode: .amber,
                    filterIntensity: 58,
                    visualBrightness: 34,
                    brightnessStrategy: .manual,
                    pwmProtectionEnabled: true,
                    autoBrightnessEnabled: false,
                    circadianFilterEnabled: true,
                    autoSleepAssistEnabled: false
                )
            ),
            DisplayPreset(
                id: "outdoor",
                title: "户外抗白",
                subtitle: "强光不发飘",
                icon: "leaf.fill",
                profile: DisplayProfile(
                    mode: .green,
                    filterIntensity: 30,
                    visualBrightness: 72,
                    brightnessStrategy: .manual,
                    pwmProtectionEnabled: true,
                    autoBrightnessEnabled: false,
                    circadianFilterEnabled: false,
                    autoSleepAssistEnabled: false
                )
            ),
            DisplayPreset(
                id: "sleep",
                title: "深夜助眠",
                subtitle: "高过滤度",
                icon: "moon.stars.fill",
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
            ),
            DisplayPreset(
                id: "cinema",
                title: "影院压白",
                subtitle: "追剧游戏",
                icon: "gamecontroller.fill",
                profile: DisplayProfile(
                    mode: .black,
                    filterIntensity: 66,
                    visualBrightness: 24,
                    brightnessStrategy: .manual,
                    pwmProtectionEnabled: true,
                    autoBrightnessEnabled: false,
                    circadianFilterEnabled: false,
                    autoSleepAssistEnabled: true
                )
            )
        ]

        switch phase {
        case .daylight:
            return [presets[0], presets[2], presets[1], presets[4]]
        case .evening:
            return [presets[0], presets[1], presets[4], presets[3]]
        case .night, .sleep:
            return [presets[3], presets[4], presets[1], presets[0]]
        }
    }
}

enum FilterIntensityBand: String {
    case nearOriginal
    case light
    case daily
    case strong
    case extreme

    static func resolve(for value: Double) -> FilterIntensityBand {
        switch value {
        case ..<11: .nearOriginal
        case 11..<31: .light
        case 31..<61: .daily
        case 61..<86: .strong
        default: .extreme
        }
    }

    var title: String {
        switch self {
        case .nearOriginal: "接近原屏"
        case .light: "轻护眼"
        case .daily: "日常舒适"
        case .strong: "强护眼"
        case .extreme: "极限夜间"
        }
    }

    var summary: String {
        switch self {
        case .nearOriginal: "只做轻微柔化，适合白天快速查看。"
        case .light: "轻度压蓝白刺激，适合日常通勤。"
        case .daily: "过滤度进入主要舒适区，适合长时间使用。"
        case .strong: "开始明显压白场和色偏，适合夜间阅读。"
        case .extreme: "极暗环境专用，优先降低主观刺激感。"
        }
    }
}
