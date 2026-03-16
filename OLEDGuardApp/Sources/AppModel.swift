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

    init(
        store: SharedStore = SharedStore(),
        engine: DisplayTuningEngine = DisplayTuningEngine(),
        bridgePlanner: SystemCapabilityBridgePlanner = SystemCapabilityBridgePlanner(),
        displayController: SystemDisplayController = SystemDisplayController()
    ) {
        let loaded = store.load()
        self.state = loaded
        self.store = store
        self.engine = engine
        self.bridgePlanner = bridgePlanner
        self.displayController = displayController
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
        state.isProtectionEnabled = true
        applyCurrentProfile()
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
        case .inactive, .background:
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
}
