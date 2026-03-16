import XCTest
@testable import OLEDGuardCore

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

    func testDisabledPWMProtectionFlagsHighRisk() {
        let engine = DisplayTuningEngine()
        let profile = DisplayProfile(
            mode: .skin,
            filterIntensity: 12,
            visualBrightness: 16,
            brightnessStrategy: .manual,
            pwmProtectionEnabled: false,
            autoBrightnessEnabled: false,
            circadianFilterEnabled: false,
            autoSleepAssistEnabled: false
        )

        let computation = engine.compute(profile: profile, date: date(hour: 23))

        XCTAssertEqual(computation.riskLevel, .high)
    }

    func testBlackModePrefersDarkSurfacesAtNight() {
        let engine = DisplayTuningEngine()
        let profile = DisplayProfile(
            mode: .black,
            filterIntensity: 72,
            visualBrightness: 24,
            brightnessStrategy: .manual,
            pwmProtectionEnabled: true,
            autoBrightnessEnabled: false,
            circadianFilterEnabled: false,
            autoSleepAssistEnabled: true
        )

        let computation = engine.compute(profile: profile, date: date(hour: 1))

        XCTAssertTrue(computation.shouldPreferDarkSurfaces)
        XCTAssertGreaterThan(computation.whitePointReduction, 20)
    }

    func testBridgePlannerGeneratesConcreteWhitePointAndFilterRecipe() {
        let planner = SystemCapabilityBridgePlanner()
        let profile = DisplayProfile(
            mode: .amber,
            filterIntensity: 64,
            visualBrightness: 22,
            brightnessStrategy: .manual,
            pwmProtectionEnabled: true,
            autoBrightnessEnabled: false,
            circadianFilterEnabled: true,
            autoSleepAssistEnabled: false
        )
        let computation = DisplayTuningEngine().compute(profile: profile, date: date(hour: 23))

        let snapshot = planner.plan(profile: profile, computation: computation)

        XCTAssertFalse(snapshot.recipes.isEmpty)
        XCTAssertTrue(snapshot.actionChecklist.contains("建议白点值"))
        XCTAssertTrue(snapshot.actionChecklist.contains("建议色彩滤镜"))
        XCTAssertTrue(snapshot.recipes.contains(where: { $0.id == "white_point_recipe" && !$0.steps.isEmpty }))
        XCTAssertTrue(snapshot.recipes.contains(where: { $0.id == "color_filter_recipe" && $0.recommendedValue.contains("暖黄") }))
    }

    func testBalancedAutomationPackIncludesMorningRestoreRule() {
        let rules = AutomationStarterPack.balanced.rules()

        XCTAssertEqual(rules.count, 3)
        XCTAssertEqual(rules[2].title, "早晨恢复")
        XCTAssertEqual(rules[2].hour, 7)
        XCTAssertEqual(rules[2].profile.filterIntensity, 0)
    }

    func testExtremeNightCalibrationRaisesProtectionAndSwitchesNightMode() {
        let base = DisplayProfile(
            mode: .skin,
            filterIntensity: 28,
            visualBrightness: 42,
            brightnessStrategy: .circadian,
            pwmProtectionEnabled: false,
            autoBrightnessEnabled: true,
            circadianFilterEnabled: true,
            autoSleepAssistEnabled: false
        )

        let adjusted = CalibrationQuickAction.extremeNight.applying(to: base, phase: .sleep)

        XCTAssertEqual(adjusted.mode, .red)
        XCTAssertGreaterThanOrEqual(adjusted.filterIntensity, 76)
        XCTAssertLessThanOrEqual(adjusted.visualBrightness, 22)
        XCTAssertTrue(adjusted.pwmProtectionEnabled)
        XCTAssertFalse(adjusted.autoBrightnessEnabled)
    }

    private func date(hour: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(year: 2026, month: 3, day: 16, hour: hour, minute: 0)
        return calendar.date(from: components) ?? .now
    }
}
