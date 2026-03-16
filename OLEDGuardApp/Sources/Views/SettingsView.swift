import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List {
            Section("当前引擎") {
                Label("模式：\(model.activeProfile.mode.title)", systemImage: "paintpalette.fill")
                Label("过滤度：\(Int(model.activeProfile.filterIntensity))%", systemImage: "slider.horizontal.3")
                Label("亮度策略：\(model.activeProfile.brightnessStrategy.title)", systemImage: "sun.max.fill")
            }

            Section("使用原则") {
                Text("过滤度是总强度，模式只决定色彩方向，亮度负责视觉明暗，一键恢复负责安全退出。")
                Text("夜间不要追求极端低亮，优先维持舒适和稳定。")
            }

            Section("工程说明") {
                Text("当前工程使用 SwiftUI + WidgetKit + App Intents，适合在云 Mac 上继续完善为正式上架版本。")
                Text("涉及系统辅助显示能力的更深层联动，需要在真机和审核约束下继续验证。")
                Text("全局白点值、色彩滤镜和极暗弱光仍需系统桥接方案，不是当前仓库单靠公开前台代码就能直接写值。")
            }

            Section("系统桥接状态") {
                ForEach(model.bridgeSnapshot.items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.title)
                                .font(.headline)
                            Spacer()
                            Text(item.supportLevel.title)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        Text(item.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("建议动作：\(item.recommendedAction)")
                            .font(.caption)
                        if let value = item.recommendedValue {
                            Text("建议值：\(value)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.96, green: 0.92, blue: 0.84))
        .navigationTitle("设置")
    }
}
