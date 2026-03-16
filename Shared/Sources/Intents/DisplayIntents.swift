import AppIntents
import Foundation

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

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = SharedStore()
        var state = store.load()
        state.activeProfile.mode = mode
        state.activeProfile.filterIntensity = filterIntensity
        state.activeProfile.visualBrightness = brightness
        state.activeProfile.autoBrightnessEnabled = false
        state.activeProfile.brightnessStrategy = .manual
        state.activeProfile.circadianFilterEnabled = mode != .black
        state.activeProfile.autoSleepAssistEnabled = mode == .red || mode == .black
        state.activeProfile.pwmProtectionEnabled = true
        state.isProtectionEnabled = true
        state.lastMutation = .now
        store.save(state)
        return .result(dialog: "已准备应用\(mode.title)模式。")
    }
}

struct RestoreDisplayIntent: AppIntent {
    static var title: LocalizedStringResource = "恢复原始显示"
    static var description = IntentDescription("清空当前护眼状态并恢复原始显示。")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = SharedStore()
        var state = store.load()
        state.isProtectionEnabled = false
        state.activeProfile = .restored
        state.lastComputation = .neutral
        state.lastMutation = .now
        store.save(state)
        return .result(dialog: "已恢复原始显示。")
    }
}

struct OLEDGuardShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: ApplyPresetIntent(mode: .amber, filterIntensity: 58, brightness: 30),
                phrases: [
                    "用 \(.applicationName) 打开阅读护眼",
                    "用 \(.applicationName) 开启黄色模式"
                ],
                shortTitle: "阅读模式",
                systemImageName: "book.fill"
            ),
            AppShortcut(
                intent: ApplyPresetIntent(mode: .red, filterIntensity: 84, brightness: 18),
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
