import AppIntents
import Foundation
import WidgetKit

private func persistStateUpdate(
    mutation: (inout AppState) -> Void
) {
    let store = SharedStore()
    let engine = DisplayTuningEngine()
    var state = store.load()
    mutation(&state)
    state.lastComputation = state.isProtectionEnabled
        ? engine.compute(profile: state.activeProfile)
        : .neutral
    state.lastMutation = .now
    store.save(state)
    WidgetCenter.shared.reloadAllTimelines()
}

struct ApplyPresetIntent: AppIntent {
    static var title: LocalizedStringResource = "应用护眼预设"
    static var description = IntentDescription("用指定模式、过滤度和亮度应用一套 OLED 护眼预设。")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "模式")
    var mode: DisplayMode

    @Parameter(title: "过滤度", default: 62)
    var filterIntensity: Double

    @Parameter(title: "亮度", default: 32)
    var brightness: Double

    init() {}

    init(mode: DisplayMode, filterIntensity: Double, brightness: Double) {
        self.init()
        self.mode = mode
        self.filterIntensity = filterIntensity
        self.brightness = brightness
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        persistStateUpdate { state in
            state.activeProfile.mode = mode
            state.activeProfile.filterIntensity = filterIntensity
            state.activeProfile.visualBrightness = brightness
            state.activeProfile.autoBrightnessEnabled = false
            state.activeProfile.brightnessStrategy = .manual
            state.activeProfile.circadianFilterEnabled = mode != .black
            state.activeProfile.autoSleepAssistEnabled = mode == .red || mode == .black
            state.activeProfile.pwmProtectionEnabled = true
            state.isProtectionEnabled = true
        }
        return .result(dialog: "已准备应用\(mode.title)模式。")
    }
}

struct RestoreDisplayIntent: AppIntent {
    static var title: LocalizedStringResource = "恢复原始显示"
    static var description = IntentDescription("清空当前护眼状态并恢复原始显示。")
    static var openAppWhenRun: Bool = true

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog {
        persistStateUpdate { state in
            state.isProtectionEnabled = false
            state.activeProfile = .restored
        }
        return .result(dialog: "已恢复原始显示。")
    }
}

struct OLEDGuardShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: ApplyPresetIntent(mode: DisplayMode.skin, filterIntensity: 28.0, brightness: 52.0),
                phrases: [
                    "用 \(.applicationName) 打开柔和模式",
                    "用 \(.applicationName) 开启肉色模式"
                ],
                shortTitle: "柔和模式",
                systemImageName: "sun.horizon.fill"
            ),
            AppShortcut(
                intent: ApplyPresetIntent(mode: DisplayMode.amber, filterIntensity: 58.0, brightness: 30.0),
                phrases: [
                    "用 \(.applicationName) 打开阅读护眼",
                    "用 \(.applicationName) 开启黄色模式"
                ],
                shortTitle: "阅读模式",
                systemImageName: "book.fill"
            ),
            AppShortcut(
                intent: ApplyPresetIntent(mode: DisplayMode.red, filterIntensity: 84.0, brightness: 18.0),
                phrases: [
                    "用 \(.applicationName) 打开助眠红光",
                    "用 \(.applicationName) 开启红色模式"
                ],
                shortTitle: "助眠模式",
                systemImageName: "moon.stars.fill"
            ),
            AppShortcut(
                intent: RestoreDisplayIntent(),
                phrases: [
                    "用 \(.applicationName) 恢复原屏",
                    "用 \(.applicationName) 关闭护眼"
                ],
                shortTitle: "恢复原屏",
                systemImageName: "arrow.counterclockwise.circle.fill"
            )
        ]
    }
}
