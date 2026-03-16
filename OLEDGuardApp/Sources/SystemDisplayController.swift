import Foundation
import UIKit

@MainActor
final class SystemDisplayController {
    func captureBaselineIfNeeded(from state: inout AppState) {
        guard state.baselineBrightness == nil else { return }
        state.baselineBrightness = Double(UIScreen.main.brightness * 100)
    }

    func apply(computation: DisplayComputation) {
        UIScreen.main.brightness = CGFloat(computation.hardwareBrightness / 100)
    }

    func restore(using state: AppState) {
        let target = (state.baselineBrightness ?? DisplayComputation.neutral.hardwareBrightness) / 100
        UIScreen.main.brightness = CGFloat(target)
    }
}
