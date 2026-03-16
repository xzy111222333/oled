import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel
    @State private var showsAutomation = false
    @State private var showsSettings = false
    @State private var showsTipBanner = true

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
                        HeaderPanel(showsAutomation: $showsAutomation, showsSettings: $showsSettings)
                        if showsTipBanner {
                            TipBanner {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showsTipBanner = false
                                }
                            }
                        }
                        AutoBrightnessStrip(model: model)
                        MainControlCard(model: model)
                        ScoreCard(model: model)
                        RestoreButtonBar(model: model)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showsAutomation) {
            NavigationStack {
                AutomationView(model: model)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("关闭") { showsAutomation = false }
                        }
                    }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showsSettings) {
            NavigationStack {
                SettingsView(model: model)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("关闭") { showsSettings = false }
                        }
                    }
            }
            .presentationDetents([.large])
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
    @Binding var showsAutomation: Bool
    @Binding var showsSettings: Bool

    var body: some View {
        HStack {
            Spacer()
            Text("护眼宝")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
            Spacer()
            HStack(spacing: 12) {
                Button {
                    showsAutomation = true
                } label: {
                    Image(systemName: "clock")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
                }
                .buttonStyle(.plain)

                Button {
                    showsSettings = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 12)
    }
}

private struct TipBanner: View {
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("PWM 安全模式已启用")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.9))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(Color(red: 0.95, green: 0.77, blue: 0.10))
        )
    }
}

private struct AutoBrightnessStrip: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: 14) {
            Text("自动亮度")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))

            Slider(
                value: Binding(
                    get: { model.activeProfile.visualBrightness },
                    set: { model.setVisualBrightness($0) }
                ),
                in: 0...100,
                step: 1
            )
            .tint(Color.gray.opacity(0.65))

            Button {
                model.setAutoBrightnessEnabled(!model.activeProfile.autoBrightnessEnabled)
            } label: {
                Circle()
                    .stroke(Color(red: 0.22, green: 0.62, blue: 0.79), lineWidth: 2)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Text("A")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
                    )
            }
            .buttonStyle(.plain)

            Button {
                model.setPWMProtectionEnabled(!model.activeProfile.pwmProtectionEnabled)
            } label: {
                Image(systemName: model.activeProfile.pwmProtectionEnabled ? "shield.fill" : "shield")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(red: 0.95, green: 0.42, blue: 0.34))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
    }
}

private struct MainControlCard: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack {
                Text("防蓝光")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
                Spacer()
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

                CapsuleToggle(
                    title: "生物钟",
                    isOn: model.activeProfile.circadianFilterEnabled,
                    action: {
                        model.setCircadianFilterEnabled(!model.activeProfile.circadianFilterEnabled)
                    }
                )
            }

            HStack(alignment: .center) {
                Text("调色")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.28, green: 0.28, blue: 0.28))
                Spacer()
                Text("自动夜间助眠")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.42, green: 0.42, blue: 0.42))
                Toggle("", isOn: Binding(
                    get: { model.activeProfile.autoSleepAssistEnabled },
                    set: { model.setAutoSleepAssistEnabled($0) }
                ))
                .labelsHidden()
                .tint(Color(red: 0.95, green: 0.81, blue: 0.71))
            }

            HStack(spacing: 18) {
                ForEach(DisplayMode.allCases) { mode in
                    ColorModeDot(
                        mode: mode,
                        isSelected: mode == model.activeProfile.mode
                    ) {
                        model.setMode(mode)
                    }
                }
            }

            HStack(spacing: 10) {
                SmallStatPill(title: "过滤度", value: "\(Int(model.activeProfile.filterIntensity))%")
                SmallStatPill(title: "安全亮度", value: "\(Int(model.computation.hardwareBrightness))%")
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

private struct ScoreCard: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("总得分：\(model.computation.comfortScore)")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                    Text(scoreSummary)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                Spacer()
                Image(systemName: scoreIcon)
                    .font(.system(size: 38, weight: .light))
            }
            .foregroundStyle(.white)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.29, green: 0.67, blue: 0.84))
            )

            HStack(spacing: 18) {
                UsageMetric(title: "今日使用手机", value: "\(model.todayUsageMinutes)分钟")
                UsageMetric(title: "疲劳使用", value: "\(model.fatigueUsageMinutes)分钟")
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.72))
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var scoreSummary: String {
        switch model.computation.riskLevel {
        case .low:
            return "距离疲劳还有30分钟"
        case .medium:
            return "建议提高过滤度或开启助眠"
        case .high:
            return "当前存在明显低亮风险"
        }
    }

    private var scoreIcon: String {
        switch model.computation.riskLevel {
        case .low: "checkmark.seal.fill"
        case .medium: "exclamationmark.circle.fill"
        case .high: "exclamationmark.triangle.fill"
        }
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
            .background(
                Capsule(style: .continuous)
                    .stroke(Color.gray.opacity(0.45), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ColorModeDot: View {
    let mode: DisplayMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(mode.accent)
                .frame(width: isSelected ? 68 : 44, height: isSelected ? 68 : 44)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                )
                .shadow(color: mode.accent.opacity(0.18), radius: 10, y: 4)
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

private struct UsageMetric: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.text")
                .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
