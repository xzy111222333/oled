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
    @Environment(\.widgetFamily) private var family
    let entry: OLEDGuardEntry

    var body: some View {
        ZStack {
            entry.state.activeProfile.mode.gradient
                .overlay(Color.black.opacity(0.12))

            switch family {
            case .systemSmall:
                smallLayout
            default:
                mediumLayout
            }
        }
        .foregroundStyle(.white)
    }

    private var mediumLayout: some View {
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

            quickActionRow
        }
        .padding(16)
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: entry.state.isProtectionEnabled ? "eye.fill" : "eye.slash.fill")
                    .font(.headline)
                Spacer()
                Text("\(Int(entry.state.activeProfile.filterIntensity))%")
                    .font(.caption2.bold())
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.18), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.state.activeProfile.mode.title)
                    .font(.headline.weight(.bold))
                Text(entry.state.lastComputation.riskLevel.title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
            }

            Text("亮度 \(Int(entry.state.lastComputation.hardwareBrightness))%")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.78))

            Spacer(minLength: 0)

            quickActionRow
        }
        .padding(14)
    }

    private var quickActionRow: some View {
        HStack(spacing: 8) {
            widgetButton(
                intent: ApplyPresetIntent(mode: .amber, filterIntensity: 58, brightness: 30),
                title: "阅读",
                systemImage: "book.fill"
            )
            widgetButton(
                intent: ApplyPresetIntent(mode: .red, filterIntensity: 84, brightness: 18),
                title: "助眠",
                systemImage: "moon.fill"
            )
            widgetButton(
                intent: RestoreDisplayIntent(),
                title: "恢复",
                systemImage: "arrow.counterclockwise.circle.fill"
            )
        }
        .labelStyle(.iconOnly)
    }

    private func widgetButton<I: AppIntent>(
        intent: I,
        title: String,
        systemImage: String
    ) -> some View {
        Button(intent: intent) {
            Label(title, systemImage: systemImage)
        }
        .buttonStyle(.borderedProminent)
        .tint(.white.opacity(0.18))
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct OLEDGuardWidgetsBundle: WidgetBundle {
    var body: some Widget {
        OLEDGuardWidget()
    }
}
