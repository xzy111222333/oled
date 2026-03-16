import AppIntents
import SwiftUI
import WidgetKit

struct OLEDGuardEntry: TimelineEntry {
    let date: Date
    let state: AppState
}

struct OLEDGuardTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> OLEDGuardEntry {
        OLEDGuardEntry(date: .now, state: .default)
    }

    func getSnapshot(in context: Context, completion: @escaping (OLEDGuardEntry) -> Void) {
        completion(OLEDGuardEntry(date: .now, state: SharedStore().load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OLEDGuardEntry>) -> Void) {
        let entry = OLEDGuardEntry(date: .now, state: SharedStore().load())
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(60 * 15)))
        completion(timeline)
    }
}

struct OLEDGuardWidgetView: View {
    let entry: OLEDGuardEntry

    var body: some View {
        ZStack {
            entry.state.activeProfile.mode.gradient

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("OLED 护眼")
                        .font(.headline)
                    Spacer()
                    Text(entry.state.isProtectionEnabled ? "开" : "关")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.18), in: Capsule())
                }

                Text(entry.state.activeProfile.mode.title)
                    .font(.title2.bold())

                HStack(spacing: 8) {
                    Text("评分 \(entry.state.lastComputation.comfortScore)")
                        .font(.caption.bold())
                    Text(entry.state.lastComputation.riskLevel.title)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.82))
                }

                Text(entry.state.lastComputation.summary)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Button(intent: ApplyPresetIntent(mode: .amber, filterIntensity: 58, brightness: 30)) {
                        Label("阅读", systemImage: "book.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.18))

                    Button(intent: ApplyPresetIntent(mode: .red, filterIntensity: 84, brightness: 18)) {
                        Label("助眠", systemImage: "moon.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.18))

                    Button(intent: RestoreDisplayIntent()) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.18))
                }
                .labelStyle(.iconOnly)
            }
            .padding(16)
            .foregroundStyle(.white)
        }
    }
}

struct OLEDGuardWidget: Widget {
    let kind: String = "OLEDGuardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OLEDGuardTimelineProvider()) { entry in
            OLEDGuardWidgetView(entry: entry)
        }
        .configurationDisplayName("OLED 护眼")
        .description("快速切换阅读、助眠和恢复原屏。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct OLEDGuardWidgetsBundle: WidgetBundle {
    var body: some Widget {
        OLEDGuardWidget()
    }
}
