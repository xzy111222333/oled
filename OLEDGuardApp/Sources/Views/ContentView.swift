import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject var model: AppModel
    @State private var selectedPack: AutomationStarterPack = .balanced
    @State private var selectedRecipeID = "white_point_recipe"
    @State private var showsCalibration = false
    @State private var showsAutomation = false

    private var selectedRecipe: CapabilityBridgeRecipe? {
        model.bridgeSnapshot.recipes.first(where: { $0.id == selectedRecipeID }) ?? model.bridgeSnapshot.recipes.first
    }

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.92, blue: 0.84)
                .ignoresSafeArea()

            Rectangle()
                .fill(Color(red: 0.28, green: 0.67, blue: 0.83))
                .frame(height: 118)
                .ignoresSafeArea(edges: .top)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    CompactHeader(model: model)
                    BrightnessStrip(model: model)
                    MainWorkbench(
                        model: model,
                        selectedPack: $selectedPack,
                        selectedRecipeID: $selectedRecipeID,
                        showsCalibration: $showsCalibration,
                        showsAutomation: $showsAutomation
                    )
                    FooterStrip(model: model)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
    }
}

private struct CompactHeader: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            Text("OLED 护眼")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(Color(red: 0.22, green: 0.62, blue: 0.79)).frame(width: 8, height: 8)
                Circle().fill(Color(red: 0.22, green: 0.62, blue: 0.79).opacity(0.55)).frame(width: 8, height: 8)
                Circle().fill(Color(red: 0.22, green: 0.62, blue: 0.79).opacity(0.35)).frame(width: 8, height: 8)
            }
        }
        .padding(.top, 8)
    }
}

private struct BrightnessStrip: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: 12) {
            Text("亮度")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))

            Slider(
                value: Binding(
                    get: { model.activeProfile.visualBrightness },
                    set: { model.setVisualBrightness($0) }
                ),
                in: 0...100,
                step: 1
            )
            .tint(Color.gray.opacity(0.55))

            Button {
                model.setAutoBrightnessEnabled(!model.activeProfile.autoBrightnessEnabled)
            } label: {
                Circle()
                    .stroke(Color(red: 0.28, green: 0.67, blue: 0.83), lineWidth: 2)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Text("A")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color(red: 0.28, green: 0.67, blue: 0.83))
                    )
            }
            .buttonStyle(.plain)

            Button {
                model.toggleProtection()
            } label: {
                Image(systemName: model.state.isProtectionEnabled ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(red: 0.96, green: 0.53, blue: 0.44))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.95, green: 0.93, blue: 0.87))
        )
    }
}

private struct MainWorkbench: View {
    @ObservedObject var model: AppModel
    @Binding var selectedPack: AutomationStarterPack
    @Binding var selectedRecipeID: String
    @Binding var showsCalibration: Bool
    @Binding var showsAutomation: Bool

    private var selectedRecipe: CapabilityBridgeRecipe? {
        model.bridgeSnapshot.recipes.first(where: { $0.id == selectedRecipeID }) ?? model.bridgeSnapshot.recipes.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PreviewPanel(model: model)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("防蓝光")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
                    Spacer()
                    Text("\(Int(model.activeProfile.filterIntensity))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
                }

                HStack(spacing: 12) {
                    Slider(
                        value: Binding(
                            get: { model.activeProfile.filterIntensity },
                            set: { model.setFilterIntensity($0) }
                        ),
                        in: 0...100,
                        step: 1
                    )
                    .tint(Color(red: 0.22, green: 0.62, blue: 0.79))

                    ToggleChip(
                        title: "生物钟",
                        isOn: model.activeProfile.circadianFilterEnabled
                    ) {
                        model.setCircadianFilterEnabled(!model.activeProfile.circadianFilterEnabled)
                    }
                }
            }

            HStack {
                Text("调色")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
                Spacer()
                ToggleChip(
                    title: "自动夜间助眠",
                    isOn: model.activeProfile.autoSleepAssistEnabled
                ) {
                    model.setAutoSleepAssistEnabled(!model.activeProfile.autoSleepAssistEnabled)
                }
            }

            HStack(spacing: 18) {
                ForEach(DisplayMode.allCases) { mode in
                    SimpleModeDot(
                        mode: mode,
                        isSelected: model.activeProfile.mode == mode
                    ) {
                        model.setMode(mode)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                SmallUtilityButton(
                    title: model.activeProfile.autoBrightnessEnabled ? "自动亮度" : "手动亮度",
                    tint: Color(red: 0.28, green: 0.67, blue: 0.83)
                ) {
                    model.setAutoBrightnessEnabled(!model.activeProfile.autoBrightnessEnabled)
                }
                SmallUtilityButton(
                    title: model.activeProfile.pwmProtectionEnabled ? "PWM 安全" : "PWM 关闭",
                    tint: Color(red: 0.96, green: 0.53, blue: 0.44)
                ) {
                    model.setPWMProtectionEnabled(!model.activeProfile.pwmProtectionEnabled)
                }
            }

            HStack(spacing: 8) {
                ForEach(CalibrationQuickAction.allCases) { action in
                    SmallActionChip(title: action.title) {
                        model.applyCalibrationAction(action)
                    }
                }
            }

            DisclosureGroup(isExpanded: $showsCalibration) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        ForEach(model.bridgeSnapshot.recipes) { recipe in
                            MiniSelectorChip(
                                title: recipe.title.replacingOccurrences(of: "桥接", with: ""),
                                isSelected: selectedRecipeID == recipe.id
                            ) {
                                selectedRecipeID = recipe.id
                            }
                        }
                    }

                    if let selectedRecipe {
                        CompactGuideCard(recipe: selectedRecipe)
                    }

                    HStack(spacing: 8) {
                        SmallActionChip(title: "复制清单") {
                            UIPasteboard.general.string = model.bridgeSnapshot.actionChecklist
                        }
                        SmallActionChip(title: "白点 \(Int(model.computation.whitePointReduction))%") {}
                    }
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Text("系统校准")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Text(model.activeProfile.mode.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
            }

            DisclosureGroup(isExpanded: $showsAutomation) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        ForEach(AutomationStarterPack.allCases) { pack in
                            MiniSelectorChip(
                                title: pack.title,
                                isSelected: selectedPack == pack
                            ) {
                                selectedPack = pack
                            }
                        }
                    }

                    Button {
                        model.applyAutomationStarterPack(selectedPack)
                    } label: {
                        Text("一键套用 \(selectedPack.title)")
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(red: 0.28, green: 0.67, blue: 0.83))
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    ForEach(selectedPack.rules()) { rule in
                        HStack {
                            Text(rule.timeLabel)
                                .font(.subheadline.monospacedDigit())
                            Text(rule.title)
                                .font(.subheadline)
                            Spacer()
                            Text(rule.profile.filterIntensity == 0 ? "恢复" : "\(Int(rule.profile.filterIntensity))%")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                    }

                    SmallActionChip(title: "复制自动化步骤") {
                        UIPasteboard.general.string = automationGuideText(for: selectedPack)
                    }
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Text("自动化")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Text("\(model.automationRules.filter(\.isEnabled).count) 条")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
            }

            Button {
                model.restoreDisplay()
            } label: {
                Text("一键恢复")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(red: 0.28, green: 0.67, blue: 0.83))
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(red: 0.28, green: 0.67, blue: 0.83), lineWidth: 3)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                )
        )
    }

    private func automationGuideText(for pack: AutomationStarterPack) -> String {
        let rules = pack.rules().map { rule in
            if rule.profile.filterIntensity == 0 {
                return "\(rule.timeLabel) 恢复原屏"
            }
            return "\(rule.timeLabel) \(rule.title)"
        }.joined(separator: "\n")

        return """
        \(pack.title)

        1. 打开快捷指令
        2. 自动化
        3. 个人自动化
        4. 时间
        5. 关闭运行前询问

        \(rules)
        """
    }
}

private struct PreviewPanel: View {
    @ObservedObject var model: AppModel

    private var overlayColor: Color {
        switch model.activeProfile.mode {
        case .skin:
            return Color(red: 0.96, green: 0.82, blue: 0.56)
        case .amber:
            return Color(red: 0.96, green: 0.86, blue: 0.33)
        case .green:
            return Color(red: 0.76, green: 0.84, blue: 0.54)
        case .red:
            return Color(red: 0.95, green: 0.63, blue: 0.43)
        case .black:
            return Color(red: 0.47, green: 0.44, blue: 0.36)
        }
    }

    private var overlayOpacity: Double {
        max(0.12, min(model.activeProfile.filterIntensity / 100 * 0.65, 0.68))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.92))

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(overlayColor.opacity(overlayOpacity))

            VStack(alignment: .leading, spacing: 10) {
                Text("实时预览")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(red: 0.18, green: 0.45, blue: 0.58))

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.82))
                    .frame(height: 44)
                    .overlay(
                        HStack {
                            Text("白底网页 / 聊天")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(model.computation.whitePointReduction))%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                    )

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(model.activeProfile.mode == .black ? 0.72 : 0.16))
                    .frame(height: 38)
                    .overlay(
                        HStack {
                            Text("夜间视频 / 游戏")
                                .font(.subheadline)
                                .foregroundStyle(model.activeProfile.mode == .black ? .white.opacity(0.9) : .primary)
                            Spacer()
                            Text(model.activeProfile.mode.title)
                                .font(.caption.bold())
                                .foregroundStyle(model.activeProfile.mode == .black ? .white.opacity(0.8) : .secondary)
                        }
                        .padding(.horizontal, 12)
                    )

                HStack {
                    Text("过滤度 \(Int(model.activeProfile.filterIntensity))%")
                        .font(.caption)
                    Spacer()
                    Text("亮度 \(Int(model.activeProfile.visualBrightness))%")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .frame(height: 150)
    }
}

private struct FooterStrip: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("总分 \(model.computation.comfortScore)")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text(model.comfortHeadline)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(red: 0.28, green: 0.67, blue: 0.83))

            HStack {
                Text("今日使用 \(model.todayUsageMinutes) 分钟")
                Spacer()
                Text("疲劳使用 \(model.fatigueUsageMinutes) 分钟")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.8))
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct ToggleChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .fill(isOn ? Color(red: 0.28, green: 0.67, blue: 0.83) : Color.clear)
                            .frame(width: 10, height: 10)
                    )
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .stroke(Color.gray.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SimpleModeDot: View {
    let mode: DisplayMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(mode.accent)
                .frame(width: isSelected ? 54 : 34, height: isSelected ? 54 : 34)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                )
                .shadow(color: mode.accent.opacity(0.22), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

private struct SmallUtilityButton: View {
    let title: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.78))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct SmallActionChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.82))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct MiniSelectorChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : Color(red: 0.22, green: 0.62, blue: 0.79))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color(red: 0.28, green: 0.67, blue: 0.83) : Color.white.opacity(0.82))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct CompactGuideCard: View {
    let recipe: CapabilityBridgeRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recipe.title)
                    .font(.subheadline.bold())
                Spacer()
                Text(recipe.recommendedValue)
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 0.96, green: 0.53, blue: 0.44))
            }

            Text(recipe.systemPath)
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(Array(recipe.steps.prefix(3).enumerated()), id: \.offset) { index, step in
                Text("\(index + 1). \(step)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
    }
}
