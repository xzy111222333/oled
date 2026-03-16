import SwiftUI

struct OnboardingView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.92, blue: 0.84).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Text("OLED 护眼引导")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.22, green: 0.62, blue: 0.79))

                OnboardingStep(
                    title: "过滤度是主轴",
                    detail: "所有模式都建立在过滤度之上。数值越高，护眼强度越强，模式色偏也越明显。"
                )
                OnboardingStep(
                    title: "亮度独立存在",
                    detail: "夜间不要一味压低硬件亮度。开启 PWM 安全保护后，系统会优先用亮度锁定和白点压制实现舒适暗化。"
                )
                OnboardingStep(
                    title: "恢复必须足够快",
                    detail: "首页和小组件都保留一键恢复入口，任何时候都能快速回到原始显示状态。"
                )

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        model.markOnboardingComplete()
                    }
                } label: {
                    Text("开始使用")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledCapsuleButtonStyle(fill: model.activeProfile.mode.accent))
            }
            .padding(24)
        }
    }
}

private struct OnboardingStep: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.78))
        )
    }
}
