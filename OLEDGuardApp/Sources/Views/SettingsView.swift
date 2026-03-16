import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List {
            Section("当前状态") {
                Label("模式：\(model.activeProfile.mode.title)", systemImage: "paintpalette.fill")
                Label("过滤度：\(Int(model.activeProfile.filterIntensity))%", systemImage: "slider.horizontal.3")
                Label("亮度策略：\(model.activeProfile.brightnessStrategy.title)", systemImage: "sun.max.fill")
                Label("风险等级：\(model.computation.riskLevel.title)", systemImage: "waveform.path.ecg")
            }

            Section("核心开关") {
                Toggle("PWM 安全保护", isOn: Binding(
                    get: { model.activeProfile.pwmProtectionEnabled },
                    set: { model.setPWMProtectionEnabled($0) }
                ))
                Toggle("生物钟过滤", isOn: Binding(
                    get: { model.activeProfile.circadianFilterEnabled },
                    set: { model.setCircadianFilterEnabled($0) }
                ))
                Toggle("自动夜间助眠", isOn: Binding(
                    get: { model.activeProfile.autoSleepAssistEnabled },
                    set: { model.setAutoSleepAssistEnabled($0) }
                ))

                Picker("亮度策略", selection: Binding(
                    get: { model.activeProfile.brightnessStrategy },
                    set: { model.setBrightnessStrategy($0) }
                )) {
                    ForEach(BrightnessStrategy.allCases) { strategy in
                        Text(strategy.title).tag(strategy)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("使用原则") {
                Text("过滤度是总强度，模式只决定色彩方向，亮度负责视觉明暗，一键恢复负责安全退出。")
                Text("夜间不要一味压低硬件亮度，优先维持舒适和稳定。")
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

            Section("系统调节操作卡") {
                Button("复制完整桥接清单") {
                    UIPasteboard.general.string = model.bridgeSnapshot.actionChecklist
                }

                ForEach(model.bridgeSnapshot.recipes) { recipe in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title)
                                    .font(.headline)
                                Text(recipe.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(recipe.recommendedValue)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.12), in: Capsule())
                        }

                        Text("路径：\(recipe.systemPath)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Text(step)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }

            Section("桥接参数导出") {
                Text(model.bridgeSnapshot.exportPayload)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                Text(model.bridgeSnapshot.actionChecklist)
                    .font(.caption)
                    .textSelection(.enabled)
            }

            Section("合规边界") {
                Text("本项目定位为显示舒适度调节工具，不承诺医疗效果。")
                Text("不使用私有 API，不做悬浮窗，不做杀后台自动恢复。")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.96, green: 0.92, blue: 0.84))
        .navigationTitle("设置")
    }
}
