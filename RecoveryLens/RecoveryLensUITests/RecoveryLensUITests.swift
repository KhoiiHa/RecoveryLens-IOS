import XCTest

final class RecoveryLensUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAuthorizationExplainsVoluntaryAccessAndCheckInStaysAvailable() {
        let app = launch(with: "-authorizationRequired")

        XCTAssertTrue(
            app.buttons["Mit Apple Health verbinden"]
                .waitForExistence(timeout: 3)
        )
        let voluntaryAccessText = app.staticTexts.matching(
            NSPredicate(
                format: "label BEGINSWITH %@",
                "Die Freigabe ist freiwillig"
            )
        ).firstMatch
        XCTAssertTrue(voluntaryAccessText.exists)

        app.tabBars.buttons["Check-in"].tap()

        XCTAssertTrue(
            app.navigationBars["Tages-Check-in"]
                .waitForExistence(timeout: 3)
        )
    }

    @MainActor
    func testInfoScreenExplainsPrivacyAndBoundaries() {
        let app = launch(with: "-demoData")

        app.tabBars.buttons["Info"].tap()

        XCTAssertTrue(
            app.navigationBars["Info & Datenschutz"]
                .waitForExistence(timeout: 3)
        )
        XCTAssertTrue(app.staticTexts["Datenquellen"].exists)
        XCTAssertTrue(app.staticTexts["Speicherung und Weitergabe"].exists)

        app.swipeUp()

        XCTAssertTrue(
            app.staticTexts["Berechtigungen"].waitForExistence(timeout: 3)
        )

        app.swipeUp()

        XCTAssertTrue(
            app.staticTexts["Fachliche Grenzen"].waitForExistence(timeout: 3)
        )

        let sleepBoundary = app.staticTexts["Schlafdauer"]
        scrollUntilHittable(sleepBoundary, in: app)
        XCTAssertTrue(sleepBoundary.isHittable)

        let privacyPolicyLink = app.descendants(matching: .any)[
            "privacy-policy-link"
        ]
        scrollUntilHittable(privacyPolicyLink, in: app)
        XCTAssertTrue(privacyPolicyLink.isHittable)

        let supportLink = app.descendants(matching: .any)[
            "support-email-link"
        ]
        scrollUntilHittable(supportLink, in: app)
        XCTAssertTrue(supportLink.isHittable)
    }

    @MainActor
    func testDashboardStatusScenarios() {
        let scenarios = [
            ("-healthKitUnavailable", "Apple Health nicht verfügbar"),
            ("-authorizationUnknown", "Status nicht bestimmbar"),
            ("-loading", "Health-Daten werden geladen"),
            ("-emptyData", "Keine Health-Daten"),
            ("-queryError", "Daten konnten nicht geladen werden"),
        ]

        for (argument, expectedTitle) in scenarios {
            let app = launch(with: argument)

            XCTAssertTrue(
                app.staticTexts[expectedTitle]
                    .waitForExistence(timeout: 3),
                "\(expectedTitle) wurde nicht dargestellt."
            )

            app.terminate()
        }
    }

    @MainActor
    func testPartialDataKeepsMissingValuesVisible() {
        let app = launch(with: "-partialData")

        XCTAssertTrue(
            app.staticTexts[
                "Einige Werte fehlen. RecoveryLens behandelt fehlende Daten nicht als gemessene Null."
            ].waitForExistence(timeout: 3)
        )
        XCTAssertTrue(app.staticTexts["Schritte, 3.250"].exists)
        XCTAssertTrue(app.staticTexts["Aktive Energie, –, Keine Daten"].exists)
    }

    @MainActor
    func testPersistenceFailureKeepsDashboardAvailable() {
        let app = XCUIApplication()
        app.launchArguments = ["-demoData", "-persistenceUnavailable"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Tageswerte"].waitForExistence(timeout: 3)
        )

        app.tabBars.buttons["Check-in"].tap()

        XCTAssertTrue(
            app.staticTexts["Lokale Check-ins sind derzeit nicht verfügbar."]
                .waitForExistence(timeout: 3)
        )
        XCTAssertFalse(app.buttons["Check-in speichern"].isEnabled)
    }

    @MainActor
    func testDemoDataShowsDashboardContent() {
        let app = launch(with: "-demoData")

        XCTAssertTrue(
            app.staticTexts["Tageswerte"].waitForExistence(timeout: 3)
        )
        XCTAssertTrue(app.staticTexts["Schritte, 8.840"].exists)
        XCTAssertTrue(
            app.buttons["Letzte sieben Tage, 3 Trainingseinheiten"].exists
        )
    }

    @MainActor
    func testCapturePortfolioScreenshots() {
        let app = launch(with: "-portfolioScreenshots")

        XCTAssertTrue(
            app.staticTexts["Tageswerte"].waitForExistence(timeout: 3)
        )
        addScreenshot(named: "01-dashboard", from: app)

        app.buttons["Letzte sieben Tage, 3 Trainingseinheiten"].tap()
        XCTAssertTrue(
            app.navigationBars["Wochenübersicht"]
                .waitForExistence(timeout: 3)
        )
        addScreenshot(named: "02-week-overview", from: app)

        app.tabBars.buttons["Check-in"].tap()
        XCTAssertTrue(
            app.navigationBars["Tages-Check-in"]
                .waitForExistence(timeout: 3)
        )
        XCTAssertTrue(
            app.staticTexts["Wie fühlst du dich heute?"]
                .waitForExistence(timeout: 3)
        )
        addScreenshot(named: "03-check-in", from: app)
    }

    @MainActor
    func testAccessibilityTextSizeKeepsPrimaryFlowUsable() {
        let app = launch(with: "-accessibilityText")

        XCTAssertTrue(
            app.navigationBars["Übersicht"].waitForExistence(timeout: 3)
        )
        addScreenshot(named: "accessibility-dashboard", from: app)

        let weekButton = app.buttons[
            "Letzte sieben Tage, 3 Trainingseinheiten"
        ]
        scrollUntilHittable(weekButton, in: app)
        XCTAssertTrue(weekButton.isHittable)
        weekButton.tap()

        XCTAssertTrue(
            app.navigationBars["Wochenübersicht"]
                .waitForExistence(timeout: 3)
        )
        XCTAssertTrue(
            app.staticTexts["7 von 7 Tagen mit Daten"].exists
        )
        addScreenshot(named: "accessibility-week-overview", from: app)

        app.tabBars.buttons["Check-in"].tap()
        XCTAssertTrue(
            app.navigationBars["Check-in"].waitForExistence(timeout: 3)
        )

        let saveButton = app.buttons["Check-in speichern"]
        scrollUntilHittable(saveButton, in: app)
        XCTAssertTrue(saveButton.isHittable)
        addScreenshot(named: "accessibility-check-in", from: app)
    }

    @MainActor
    private func launch(with argument: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [argument]
        app.launch()
        return app
    }

    private func addScreenshot(
        named name: String,
        from app: XCUIApplication
    ) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func scrollUntilHittable(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maximumSwipes: Int = 8
    ) {
        for _ in 0..<maximumSwipes where !element.isHittable {
            app.swipeUp()
        }
    }
}
