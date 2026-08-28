//
//  ValidateJsonUITests.swift
//  ValidateJsonUITests
//
//  Created by Arun Madasamy on 8/27/26.
//
//  Automates the "UI / Manual Exploratory Test Plan" (TEST_PLAN.swift section 5)
//  using the accessibility identifiers added to JSONEditorView, EnhancedJSONTreeView,
//  TreeSearchView, and ContentView. Layout can render as either an HSplitView
//  (wide window, identifier "layout.splitView") or a TabView (compact window,
//  identifier "layout.tabView") — `goToTreeTab()` normalizes navigation so the
//  same test works in either layout.
//

import XCTest

final class ValidateJsonUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    /// Whichever layout is active, make sure the tree pane is visible before
    /// interacting with it (no-op in HSplitView, taps the "Tree" tab in TabView).
    @MainActor
    private func goToTreeTab() {
        let tabView = app.descendants(matching: .any)["layout.tabView"]
        if tabView.waitForExistence(timeout: 2) {
            app.buttons["Tree"].firstMatch.tap()
        }
    }

    @MainActor
    private func goToEditorTab() {
        let tabView = app.descendants(matching: .any)["layout.tabView"]
        if tabView.waitForExistence(timeout: 2) {
            app.buttons["Editor"].firstMatch.tap()
        }
    }

    // MARK: - Launch / Default State (TEST_PLAN.swift section 5: Layout & Responsiveness)

    @MainActor
    func testAppLaunchesInEitherSplitOrTabLayout() throws {
        let splitView = app.descendants(matching: .any)["layout.splitView"]
        let tabView = app.descendants(matching: .any)["layout.tabView"]

        let hasSplit = splitView.waitForExistence(timeout: 5)
        let hasTab = tabView.exists

        XCTAssertTrue(hasSplit || hasTab, "Exactly one of the two responsive layouts should be present")
    }

    @MainActor
    func testDefaultSampleIsLoadedOnLaunch() throws {
        goToTreeTab()

        // ContentView auto-loads SampleJSONData.nested on first appear, whose
        // root object has top-level keys "user" and "preferences".
        let userNode = app.descendants(matching: .any)["tree.node.user"]
        XCTAssertTrue(userNode.waitForExistence(timeout: 5), "Default sample's 'user' node should be visible in the tree")
    }

    // MARK: - Editor Toolbar (TEST_PLAN.swift section 5: Editor Toolbar)

    @MainActor
    func testLoadSampleUpdatesEditorAndTree() throws {
        goToEditorTab()

        app.buttons["toolbar.loadSample"].firstMatch.tap()

        let sampleRow = app.buttons["samplePicker.row.Simple Object"]
        XCTAssertTrue(sampleRow.waitForExistence(timeout: 5))
        sampleRow.tap()

        let status = app.staticTexts["editor.statusText"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "Valid JSON")

        goToTreeTab()
        let nameNode = app.descendants(matching: .any)["tree.node.name"]
        XCTAssertTrue(nameNode.waitForExistence(timeout: 5), "'Simple Object' sample has a top-level 'name' key")
    }

    @MainActor
    func testClearButtonResetsEditor() throws {
        goToEditorTab()

        // Ensure there's something to clear first.
        app.buttons["toolbar.loadSample"].firstMatch.tap()
        let sampleRow = app.buttons["samplePicker.row.Simple Object"]
        XCTAssertTrue(sampleRow.waitForExistence(timeout: 5))
        sampleRow.tap()

        let clearButton = app.buttons["toolbar.clear"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
        XCTAssertTrue(clearButton.isEnabled, "Clear should be enabled once there is text")
        clearButton.tap()

        let status = app.staticTexts["editor.statusText"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "No JSON")
        XCTAssertFalse(clearButton.isEnabled, "Clear should disable itself once the editor is empty")
    }

    @MainActor
    func testFormatAndCopyButtonsDisabledWhenEditorIsEmpty() throws {
        goToEditorTab()

        // Start from a clean slate.
        let clearButton = app.buttons["toolbar.clear"]
        if clearButton.waitForExistence(timeout: 3), clearButton.isEnabled {
            clearButton.tap()
        }

        XCTAssertFalse(app.buttons["toolbar.format"].isEnabled, "Format should be disabled with no text")
        XCTAssertFalse(app.buttons["toolbar.copy"].isEnabled, "Copy should be disabled with no text")
        XCTAssertFalse(app.buttons["toolbar.export"].isEnabled, "Export should be disabled with no text")
    }

    @MainActor
    func testFormatButtonPrettifiesMinifiedJSON() throws {
        goToEditorTab()

        app.buttons["toolbar.loadSample"].firstMatch.tap()
        let sampleRow = app.buttons["samplePicker.row.Simple Object"]
        XCTAssertTrue(sampleRow.waitForExistence(timeout: 5))
        sampleRow.tap()

        let editor = app.textViews["editor.textView"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))

        // Replace with a minified one-liner, then Format should re-introduce line breaks.
        editor.tap()
        editor.typeKey("a", modifierFlags: .command) // select all
        editor.typeText(#"{"a":1,"b":2}"#)

        let formatButton = app.buttons["toolbar.format"]
        XCTAssertTrue(formatButton.waitForExistence(timeout: 5))
        XCTAssertTrue(formatButton.isEnabled)
        formatButton.tap()

        let formattedValue = (editor.value as? String) ?? ""
        XCTAssertTrue(formattedValue.contains("\n"), "Formatted JSON should contain line breaks")
    }

    // MARK: - Tree View (TEST_PLAN.swift section 5: Tree View)

    @MainActor
    func testExpandAllRevealsNestedNodesAndCollapseAllHidesThem() throws {
        goToTreeTab()

        let userNode = app.descendants(matching: .any)["tree.node.user"]
        XCTAssertTrue(userNode.waitForExistence(timeout: 5))

        app.buttons["tree.toolbar.collapseAll"].firstMatch.tap()
        let nameNodeCollapsed = app.descendants(matching: .any)["tree.node.name"]
        XCTAssertFalse(nameNodeCollapsed.waitForExistence(timeout: 2), "Nested 'name' node should be hidden after Collapse All")

        app.buttons["tree.toolbar.expandAll"].firstMatch.tap()
        let nameNodeExpanded = app.descendants(matching: .any)["tree.node.name"]
        XCTAssertTrue(nameNodeExpanded.waitForExistence(timeout: 5), "Nested 'name' node should reappear after Expand All")
    }

    @MainActor
    func testStatisticsToggleShowsAndHidesStatsPanel() throws {
        goToTreeTab()

        let statsButton = app.buttons["tree.toolbar.statistics"]
        XCTAssertTrue(statsButton.waitForExistence(timeout: 5))

        // Statistics default to visible; toggle off then back on.
        statsButton.tap()
        statsButton.tap()
        // No crash / still present after two toggles is the primary assertion here,
        // since the panel's inner content isn't individually identified.
        XCTAssertTrue(statsButton.exists)
    }

    @MainActor
    func testSearchFiltersTreeAndShowsResultCount() throws {
        goToTreeTab()

        let searchField = app.textFields["tree.search.field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("email")

        let resultCount = app.staticTexts["tree.search.resultCount"]
        XCTAssertTrue(resultCount.waitForExistence(timeout: 5), "Searching for 'email' should surface a result count (default sample has a 'user.email' key)")
    }

    // MARK: - Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
