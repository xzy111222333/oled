import SwiftUI

struct AutomationView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("当前节律")
                        .font(.headline)
                    Text(model.automationSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(model.recommendationBannerText())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("自动调节规则") {
                ForEach(model.automationRules) { rule in
                    AutomationRuleCard(rule: rule, model: model)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }

            Section("推荐节律") {
                RhythmHintRow(
                    title: "白天",
                    summary: "低过滤度，主打自然和清晰。",
                    accent: DisplayMode.skin.accent
                )
                RhythmHintRow(
                    title: "傍晚",
                    summary: "逐步提高过滤度，开始压白场。",
                    accent: DisplayMode.amber.accent
                )
                RhythmHintRow(
                    title: "夜间",
                    summary: "高过滤度配中低亮度，优先舒适感。",
                    accent: DisplayMode.black.accent
                )
                RhythmHintRow(
                    title: "深夜",
                    summary: "助眠红光或黑色模式，降低刺激。",
                    accent: DisplayMode.red.accent
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.96, green: 0.92, blue: 0.84))
        .navigationTitle("自动化")
    }
}

private struct AutomationRuleCard: View {
    let rule: AutomationRule
    @ObservedObject var model: AppModel
    @State private var selectedDate: Date

    init(rule: AutomationRule, model: AppModel) {
        self.rule = rule
        self.model = model
        self._selectedDate = State(initialValue: Calendar.current.date(
            bySettingHour: rule.hour,
            minute: rule.minute,
            second: 0,
            of: .now
        ) ?? .now)
    }

    private var intensityBand: FilterIntensityBand {
        FilterIntensityBand.resolve(for: rule.profile.filterIntensity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(rule.title)
                        .font(.headline)
                    Text("\(rule.profile.mode.title) · \(intensityBand.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { rule.isEnabled },
                    set: { model.toggleRule(rule.id, isEnabled: $0) }
                ))
                .labelsHidden()
            }

            HStack(spacing: 10) {
                RuleMetric(title: "过滤度", value: "\(Int(rule.profile.filterIntensity))%")
                RuleMetric(title: "亮度", value: "\(Int(rule.profile.visualBrightness))%")
                RuleMetric(title: "时间", value: rule.timeLabel)
            }

            DatePicker(
                "执行时间",
                selection: Binding(
                    get: { selectedDate },
                    set: {
                        selectedDate = $0
                        model.updateRuleTime(rule.id, date: $0)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)

            Button {
                model.applyRule(rule)
            } label: {
                Label("立刻执行这条规则", systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(rule.profile.mode.accent)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.92))
        )
    }
}

private struct RhythmHintRow: View {
    let title: String
    let summary: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(accent)
                .frame(width: 14, height: 14)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct RuleMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
