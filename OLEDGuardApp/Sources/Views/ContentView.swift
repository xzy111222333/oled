import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(red: 0.96, green: 0.92, blue: 0.84)
                    .ignoresSafeArea()

                Rectangle()
                    .fill(Color(red: 0.29, green: 0.67, blue: 0.84))
                    .frame(height: 150)
                    .ignoresSafeArea(edges: .top)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        HeaderPanel(model: model)
                        StatusHeroCard(model: model)
                        PresetShelf(model: model)
                        MainControlCard(model: model)
                        CalibrationWorkbenchCard(model: model)
                        AutomationSetupCard(model: model)
                        RestoreButtonBar(model: model)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .overlay {
            if !model.state.hasCompletedOnboarding {
                OnboardingView(model: model)
                    .transition(.opacity)
            }
        }
    }
}

private struct HeaderPanel: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OLED 护眼")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))

            HStack(spacing: 10) {
                SmallStatPill(title: "模式", value: model.activeProfile.mode.title)
                SmallStatPill(title: "过滤度", value: "\(Int(model.activeProfile.filterIntensity))%")
                SmallStatPill(title: "硬件亮度", value: "\(Int(model.computation.hardwareBrightness))%")
            }
        }
        .padding(.top, 12)
    }
}

private struct StatusHeroCard: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.protectionStatusTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(model.protectionStatusDetail)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(3)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text(model.computation.phase.label)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.18), in: Capsule())
                    Text(model.intensityBand.title)
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.82))
                }
            }

            HStack(spacing: 10) {
                HeroMetric(title: "模式", value: model.activeProfile.mode.title)
                HeroMetric(title: "过滤度", value: "\(Int(model.activeProfile.filterIntensity))%")
                HeroMetric(title: "视觉亮度", value: "\(Int(model.computation.visualBrightness))%")
            }

            Text(model.recommendationBannerText())
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            model.activeProfile.mode.accent.opacity(0.92),
                            Color(red: 0.26, green: 0.53, blue: 0.67)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

private struct PresetShelf: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("场景预设")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.28, green: 0.28, blue: 0.28))
                Spacer()
                Text("一页搞定，不跳设置")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.recommendedPresets) { preset in
                        PresetCard(
                            preset: preset,
                            isActive: preset.profile.mode == model.activeProfile.mode &&
                                Int(preset.profile.filterIntensity) == Int(model.activeProfile.filterIntensity)
                        ) {
                            model.applyPreset(preset)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct MainControlCard: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("主控面板")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
                    Text("过滤度控制总强度，亮度负责主观明暗，模式负责颜色方向。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                SmallStatPill(title: "强度分段", value: model.intensityBand.title)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("过滤度")
                    .font(.headline)
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

                    Button {
                        model.toggleProtection()
                    } label: {
                        Circle()
                            .fill(Color(red: 0.93, green: 0.91, blue: 0.80))
                            .frame(width: 62, height: 62)
                            .overlay(
                                Image(systemName: model.state.isProtectionEnabled ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("亮度")
                        .font(.headline)
                    Spacer()
                    Text(model.activeProfile.autoBrightnessEnabled ? "自动" : "手动")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { model.activeProfile.visualBrightness },
                        set: { model.setVisualBrightness($0) }
                    ),
                    in: 0...100,
                    step: 1
                )
                .tint(Color.gray.opacity(0.65))

                HStack(spacing: 12) {
                    MiniControlChip(
                        title: model.activeProfile.autoBrightnessEnabled ? "自动亮度" : "手动亮度",
                        systemImage: model.activeProfile.autoBrightnessEnabled ? "sun.max.fill" : "slider.horizontal.3",
                        tint: Color(red: 0.22, green: 0.62, blue: 0.79)
                    ) {
                        model.setAutoBrightnessEnabled(!model.activeProfile.autoBrightnessEnabled)
                    }

                    MiniControlChip(
                        title: model.activeProfile.pwmProtectionEnabled ? "PWM 安全" : "关闭保护",
                        systemImage: model.activeProfile.pwmProtectionEnabled ? "shield.fill" : "shield",
                        tint: Color(red: 0.95, green: 0.42, blue: 0.34)
                    ) {
                        model.setPWMProtectionEnabled(!model.activeProfile.pwmProtectionEnabled)
                    }
                }
            }

            HStack(spacing: 10) {
                CapsuleToggle(
                    title: "生物钟",
                    isOn: model.activeProfile.circadianFilterEnabled,
                    action: {
                        model.setCircadianFilterEnabled(!model.activeProfile.circadianFilterEnabled)
                    }
                )
                CapsuleToggle(
                    title: "夜间助眠",
                    isOn: model.activeProfile.autoSleepAssistEnabled,
                    action: {
                        model.setAutoSleepAssistEnabled(!model.activeProfile.autoSleepAssistEnabled)
                    }
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("调色模式")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.28, green: 0.28, blue: 0.28))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 12) {
                    ForEach(DisplayMode.allCases) { mode in
                        ModeChoiceButton(
                            mode: mode,
                            isSelected: mode == model.activeProfile.mode
                        ) {
                            model.setMode(mode)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                SmallStatPill(title: "过滤度", value: "\(Int(model.activeProfile.filterIntensity))%")
                SmallStatPill(title: "白点建议", value: "\(Int(model.computation.whitePointReduction))%")
                SmallStatPill(title: "蓝光削减", value: "\(Int(model.computation.blueLightReduction))%")
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(red: 0.96, green: 0.95, blue: 0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color(red: 0.22, green: 0.62, blue: 0.79), lineWidth: 3)
                )
        )
    }
}

private struct CalibrationWorkbenchCard: View {
    @ObservedObject var model: AppModel
    @State private var selectedRecipeID = "white_point_recipe"

    private var selectedRecipe: CapabilityBridgeRecipe? {
        model.bridgeSnapshot.recipes.first(where: { $0.id == selectedRecipeID }) ?? model.bridgeSnapshot.recipes.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("白点值 / 滤镜 / 恢复校准")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("这块专门负责把系统设置和当前护眼方案对齐。先看推荐值，再照着系统路径调。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("复制清单") {
                    UIPasteboard.general.string = model.bridgeSnapshot.actionChecklist
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.22, green: 0.62, blue: 0.79))
            }

            HStack(spacing: 10) {
                SmallStatPill(title: "白点建议", value: "\(Int(model.computation.whitePointReduction))%")
                SmallStatPill(title: "滤镜模式", value: model.activeProfile.mode.title)
                SmallStatPill(title: "恢复", value: "一键")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(model.bridgeSnapshot.recipes) { recipe in
                        SelectableChip(
                            title: recipe.title.replacingOccurrences(of: "桥接", with: ""),
                            isSelected: selectedRecipeID == recipe.id
                        ) {
                            selectedRecipeID = recipe.id
                        }
                    }
                }
            }

            if let selectedRecipe {
                CalibrationRecipeCard(recipe: selectedRecipe)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("快速微调")
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                    ForEach(CalibrationQuickAction.allCases) { action in
                        Button {
                            model.applyCalibrationAction(action)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(action.title)
                                    .font(.subheadline.bold())
                                Text(action.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(red: 0.96, green: 0.95, blue: 0.88))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("点一次就会重算过滤度、亮度和系统桥接建议，不用你自己瞎试。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1.2)
                )
        )
    }
}

private struct CalibrationRecipeCard: View {
    let recipe: CapabilityBridgeRecipe

    var body: some View {
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

            Text(recipe.systemPath)
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
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
    }
}

private struct AutomationSetupCard: View {
    @ObservedObject var model: AppModel
    @State private var selectedPack: AutomationStarterPack = .balanced

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("自动化一键配置")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("先一键套用 App 内时间表，再按步骤把快捷指令补上，自动化就顺了。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("复制步骤") {
                    UIPasteboard.general.string = automationGuideText(for: selectedPack)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.22, green: 0.62, blue: 0.79))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AutomationStarterPack.allCases) { pack in
                        AutomationPackButton(
                            pack: pack,
                            isSelected: selectedPack == pack
                        ) {
                            selectedPack = pack
                        }
                    }
                }
            }

            Button {
                model.applyAutomationStarterPack(selectedPack)
            } label: {
                HStack {
                    Text("一键套用 \(selectedPack.title)")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "bolt.fill")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.22, green: 0.62, blue: 0.79))
                )
            }
            .buttonStyle(.plain)

            Text(selectedPack.summary)
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(selectedPack.rules()) { rule in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(rule.timeLabel)
                            .font(.headline.monospacedDigit())
                        Spacer()
                        Text(rule.profile.filterIntensity == 0 ? "恢复原屏" : rule.profile.mode.title)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.12), in: Capsule())
                    }
                    Text(rule.title)
                        .font(.subheadline.bold())
                    Text(rule.profile.filterIntensity == 0
                         ? "这个时间点让 App 自动回原屏状态。"
                         : "过滤度 \(Int(rule.profile.filterIntensity))%，视觉亮度 \(Int(rule.profile.visualBrightness))%。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.96, green: 0.95, blue: 0.88))
                )
            }

            HStack(spacing: 10) {
                SmallStatPill(title: "App 内规则", value: "\(model.automationRules.filter(\.isEnabled).count)")
                SmallStatPill(title: "当前时段", value: model.computation.phase.label)
                SmallStatPill(title: "推荐套装", value: model.recommendedAutomationPack.title)
            }

            Text(model.automationPackSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1.2)
                )
        )
    }

    private func automationGuideText(for pack: AutomationStarterPack) -> String {
        let ruleLines = pack.rules().map { rule in
            if rule.profile.filterIntensity == 0 {
                return "- \(rule.timeLabel) 运行 OLED 护眼恢复原屏"
            }
            return "- \(rule.timeLabel) 运行 OLED 护眼\(rule.title)"
        }.joined(separator: "\n")

        return """
        OLEDGuard 自动化配置清单

        当前套装：\(pack.title)

        1. 打开 iPhone 快捷指令
        2. 进入“自动化”
        3. 创建“个人自动化”
        4. 选择“时间”
        5. 关闭“运行前询问”

        推荐三条：
        \(ruleLines)
        """
    }
}

private struct RestoreButtonBar: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Button {
            model.restoreDisplay()
        } label: {
            HStack {
                Text("一键恢复")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Spacer()
                Text("恢复原始显示")
                    .font(.subheadline)
                Image(systemName: "arrow.counterclockwise.circle.fill")
            }
            .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.98, green: 0.97, blue: 0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color(red: 0.22, green: 0.62, blue: 0.79), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CapsuleToggle: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "circle.inset.filled" : "circle")
                Text(title)
                    .font(.subheadline)
            }
            .foregroundStyle(Color(red: 0.42, green: 0.42, blue: 0.42))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                Capsule(style: .continuous)
                    .stroke(Color.gray.opacity(0.45), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SmallStatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
    }
}

private struct HeroMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.75))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Color(red: 0.22, green: 0.62, blue: 0.79))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color(red: 0.22, green: 0.62, blue: 0.79) : Color.white)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct PresetCard: View {
    let preset: DisplayPreset
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: preset.icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(preset.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                Text(preset.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text("\(Int(preset.profile.filterIntensity))%")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.7), in: Capsule())
            }
            .padding(16)
            .frame(width: 144, height: 152, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(preset.profile.mode.accent.opacity(isActive ? 0.9 : 0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(isActive ? Color.white : Color.clear, lineWidth: 2)
                    )
            )
            .foregroundStyle(Color(red: 0.19, green: 0.18, blue: 0.17))
        }
        .buttonStyle(.plain)
    }
}

private struct AutomationPackButton: View {
    let pack: AutomationStarterPack
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(pack.title)
                    .font(.headline)
                Text(pack.summary)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.86) : .secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            .padding(14)
            .frame(width: 156, height: 110, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? Color(red: 0.22, green: 0.62, blue: 0.79) : Color.white)
            )
            .foregroundStyle(isSelected ? .white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

private struct MiniControlChip: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ModeChoiceButton: View {
    let mode: DisplayMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(mode.accent)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: mode.accent.opacity(0.22), radius: 8, y: 3)
                Text(mode.title)
                    .font(.caption.bold())
                Text(mode.shortLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? mode.accent.opacity(0.16) : Color.white.opacity(0.74))
            )
        }
        .buttonStyle(.plain)
    }
}
