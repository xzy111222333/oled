import XCTest
@testable import OLEDGuard

final class DisplayEngineTests: XCTestCase {
    func testLowVisualBrightnessUsesSafetyFloor() {
        let engine = DisplayTuningEngine()
        let profile = DisplayProfile(
            mode: .red,
            filterIntensity: 80,
            visualBrightness: 18,
            brightnessStrategy: .manual,
            pwmProtectionEnabled: true,
            autoBrightnessEnabled: false,
            circadianFilterEnabled: true,
            autoSleepAssistEnabled: true
        )

        let computation = engine.compute(profile: profile, date: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(computation.hardwareBrightness, 35, accuracy: 0.1)
        XCTAssertGreaterThan(computation.whitePointReduction, 0)
    }

    func testHighVisualBrightnessBypassesWhitePointClamp() {
        let engine = DisplayTuningEngine()
        let profile = DisplayProfile(
            mode: .skin,
            filterIntensity: 10,
            visualBrightness: 70,
            brightnessStrategy: .manual,
            pwmProtectionEnabled: true,
            autoBrightnessEnabled: false,
            circadianFilterEnabled: false,
            autoSleepAssistEnabled: false
        )

        let computation = engine.compute(profile: profile, date: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(computation.hardwareBrightness, 70, accuracy: 0.1)
        XCTAssertLessThan(computation.whitePointReduction, 5)
    }

    func testCircadianStrategyChangesBrightnessAcrossPhases() {
        let engine = DisplayTuningEngine()
        let profile = DisplayProfile(
            mode: .skin,
            filterIntensity: 22,
            visualBrightness: 48,
            brightnessStrategy: .circadian,
            pwmProtectionEnabled: true,
            autoBrightnessEnabled: true,
            circadianFilterEnabled: true,
            autoSleepAssistEnabled: false
        )

        let daylight = engine.compute(profile: profile, date: date(hour: 10))
        let sleep = engine.compute(profile: profile, date: date(hour: 1))

        XCTAssertGreaterThan(daylight.visualBrightness, sleep.visualBrightness)
    }

    private func date(hour: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 2026, month: 3, day: 16, hour: hour, minute: 0)
        return calendar.date(from: components) ?? .now
    }
}
