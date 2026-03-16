import Foundation

struct DisplayTuningEngine {
    let safetyFloor: Double = 35

    func compute(profile: DisplayProfile, date: Date = .now) -> DisplayComputation {
        let phase = CircadianPhase.resolve(date: date)
        let visualBrightness = adjustedVisualBrightness(for: profile, phase: phase)
        let intensity = profile.filterIntensity.clamped(to: 0...100) / 100

        let hardwareBrightness: Double
        let brightnessDrivenWhitePoint: Double

        if profile.pwmProtectionEnabled && visualBrightness < safetyFloor {
            hardwareBrightness = safetyFloor
            brightnessDrivenWhitePoint = remap(visualBrightness, from: 0...safetyFloor, to: 96...0)
        } else {
            hardwareBrightness = visualBrightness
            brightnessDrivenWhitePoint = 0
        }

        let mode = profile.mode.spectrum
        let modeDrivenWhitePoint = mode.whitePointBias * intensity * 100
        let whitePointReduction = max(brightnessDrivenWhitePoint, modeDrivenWhitePoint).clamped(to: 0...100)
        let colorStrength = (intensity * 100).clamped(to: 0...100)
        let blueLightReduction = (mode.blueCut * intensity * 100).clamped(to: 0...100)
        let lowLightBoost = (mode.lowLightBoost * intensity * 100).clamped(to: 0...100)
        let shouldPreferDarkSurfaces = mode.prefersDarkSurfaces || phase == .sleep
        let riskLevel = computeRiskLevel(profile: profile, hardwareBrightness: hardwareBrightness, whitePoint: whitePointReduction)
        let comfortScore = computeComfortScore(
            profile: profile,
            hardwareBrightness: hardwareBrightness,
            whitePoint: whitePointReduction,
            blueLightReduction: blueLightReduction,
            riskLevel: riskLevel
        )

        return DisplayComputation(
            phase: phase,
            hardwareBrightness: hardwareBrightness.rounded(),
            visualBrightness: visualBrightness.rounded(),
            whitePointReduction: whitePointReduction.rounded(),
            colorStrength: colorStrength.rounded(),
            blueLightReduction: blueLightReduction.rounded(),
            lowLightBoost: lowLightBoost.rounded(),
            shouldPreferDarkSurfaces: shouldPreferDarkSurfaces,
            riskLevel: riskLevel,
            comfortScore: comfortScore,
            summary: summaryText(profile: profile, hardwareBrightness: hardwareBrightness, whitePoint: whitePointReduction, phase: phase)
        )
    }

    private func adjustedVisualBrightness(for profile: DisplayProfile, phase: CircadianPhase) -> Double {
        guard profile.brightnessStrategy == .circadian || profile.autoBrightnessEnabled else {
            return profile.visualBrightness.clamped(to: 1...100)
        }

        let base = profile.visualBrightness
        let offset: Double
        switch phase {
        case .daylight: offset = 16
        case .evening: offset = 2
        case .night: offset = -12
        case .sleep: offset = -22
        }

        return (base + offset).clamped(to: 1...100)
    }

    private func summaryText(
        profile: DisplayProfile,
        hardwareBrightness: Double,
        whitePoint: Double,
        phase: CircadianPhase
    ) -> String {
        if profile.filterIntensity <= 0.1 {
            return "已恢复接近原屏状态"
        }

        return "\(phase.label) · \(profile.mode.title)模式 · 硬件亮度 \(Int(hardwareBrightness))% · 白点压制 \(Int(whitePoint))%"
    }

    private func remap(_ value: Double, from: ClosedRange<Double>, to: ClosedRange<Double>) -> Double {
        guard from.lowerBound != from.upperBound else { return to.lowerBound }
        let normalized = (value - from.lowerBound) / (from.upperBound - from.lowerBound)
        return to.lowerBound + (to.upperBound - to.lowerBound) * normalized
    }

    private func computeRiskLevel(
        profile: DisplayProfile,
        hardwareBrightness: Double,
        whitePoint: Double
    ) -> ProtectionRiskLevel {
        if !profile.pwmProtectionEnabled && hardwareBrightness < safetyFloor {
            return .high
        }
        if whitePoint >= 65 || hardwareBrightness >= safetyFloor {
            return .low
        }
        return .medium
    }

    private func computeComfortScore(
        profile: DisplayProfile,
        hardwareBrightness: Double,
        whitePoint: Double,
        blueLightReduction: Double,
        riskLevel: ProtectionRiskLevel
    ) -> Int {
        var score = 55.0

        if profile.pwmProtectionEnabled && hardwareBrightness >= safetyFloor {
            score += 18
        }
        score += min(whitePoint * 0.12, 12)
        score += min(blueLightReduction * 0.15, 10)
        if profile.autoSleepAssistEnabled {
            score += 5
        }
        if profile.circadianFilterEnabled {
            score += 5
        }

        switch riskLevel {
        case .low:
            score += 8
        case .medium:
            break
        case .high:
            score -= 18
        }

        return Int(score.clamped(to: 0...100).rounded())
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
