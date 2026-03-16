import SwiftUI

struct AutomationView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List {
            Section("自动调节规则") {
                ForEach(model.automationRules) { rule in
                    AutomationRuleCard(rule: rule, model: model)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }

            Section("生物钟逻辑") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("白天低干预，傍晚逐步柔和，夜间增强白场压制，深夜偏向红光与极暗。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("这一层做的是长期可用的时间驱动，而不是复杂且不稳定的场景识别。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.title)
                        .font(.headline)
                    Text("\(rule.profile.mode.title) · 过滤度 \(Int(rule.profile.filterIntensity))% · 亮度 \(Int(rule.profile.visualBrightness))%")
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
            }
            .buttonStyle(.bordered)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.92))
        )
    }
}
