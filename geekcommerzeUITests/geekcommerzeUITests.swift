import XCTest

final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Reset onboarding so it always shows on test launch
        app.launchArguments += ["-hasSeenOnboarding", "false"]
    }

    // MARK: - Main screenshot capture test

    @MainActor
    func testCaptureAllScreens() throws {
        app.launch()

        // ── 1. Onboarding ─────────────────────────────────────────────
        let skipBtn = app.buttons["Skip"]
        let nextBtn = app.buttons["Next"]

        if skipBtn.waitForExistence(timeout: 4) || nextBtn.waitForExistence(timeout: 4) {
            snap("01_Onboarding")
            // Swipe to second page for variety
            if nextBtn.exists { nextBtn.tap(); sleep(1) }
            snap("02_Onboarding_Page2")
            if nextBtn.exists { nextBtn.tap(); sleep(1) }
            // Page 3 shows "Get Started"
            let getStarted = app.buttons["Get Started"]
            if getStarted.waitForExistence(timeout: 2) {
                snap("03_Onboarding_Page3")
                getStarted.tap()
            } else if skipBtn.exists {
                skipBtn.tap()
            }
        }

        // ── 2. Dismiss promo popup ─────────────────────────────────────
        sleep(2) // allow popup to appear (fires after 0.6 s)
        let promoSheet = app.scrollViews.firstMatch
        if promoSheet.exists {
            snap("04_PromoPopup")
            // Swipe down to dismiss the sheet
            app.swipeDown()
            sleep(1)
        }

        // ── 3. Home ───────────────────────────────────────────────────
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 5) { homeTab.tap() }
        sleep(1)
        snap("05_Home")

        // ── 4. Notifications (bell in Home toolbar) ───────────────────
        // The bell is the rightmost toolbar button on the Home navigation bar
        let navBars = app.navigationBars
        let bellBtn = navBars.buttons.element(boundBy: 0)
        if bellBtn.exists {
            bellBtn.tap()
            sleep(1)
            snap("06_Notifications")
            app.navigationBars.buttons.element(boundBy: 0).tap() // back
            sleep(1)
        }

        // ── 5. Search ─────────────────────────────────────────────────
        let searchTab = app.tabBars.buttons["Search"]
        searchTab.tap()
        sleep(1)
        snap("07_Search")

        // Type a query to show results
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.typeText("laptop")
            sleep(1)
            snap("08_Search_Results")
            // Clear search
            let clearBtn = app.buttons["Clear text"]
            if clearBtn.exists { clearBtn.tap() }
            app.keyboards.buttons["Cancel"].tap()
        }

        // ── 6. Shop ───────────────────────────────────────────────────
        let shopTab = app.tabBars.buttons["Shop"]
        shopTab.tap()
        sleep(1)
        snap("09_Shop")

        // ── 7. Product Detail ─────────────────────────────────────────
        // Tap the first product card in the shop grid
        let firstProduct = app.scrollViews.firstMatch.cells.firstMatch
        if firstProduct.waitForExistence(timeout: 3) {
            firstProduct.tap()
        } else {
            // Fallback: tap first button that looks like a product
            app.scrollViews.firstMatch.children(matching: .other).element(boundBy: 0).tap()
        }
        sleep(1)
        snap("10_ProductDetail")

        // Scroll down to see more content
        app.swipeUp()
        sleep(1)
        snap("11_ProductDetail_Scrolled")

        // Back to Shop
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)

        // ── 8. Cart ───────────────────────────────────────────────────
        let cartTab = app.tabBars.buttons["Cart"]
        cartTab.tap()
        sleep(1)
        snap("12_Cart")

        // ── 9. Checkout (only if cart has items) ──────────────────────
        let checkoutBtn = app.buttons["Proceed to Checkout"]
        if checkoutBtn.waitForExistence(timeout: 2) {
            checkoutBtn.tap()
            sleep(1)
            snap("13_Checkout")
            // Scroll for payment section
            app.swipeUp()
            sleep(1)
            snap("14_Checkout_Payment")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }

        // ── 10. Profile ───────────────────────────────────────────────
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        sleep(1)
        snap("15_Profile")

        // Scroll down to see loyalty & settings
        app.swipeUp()
        sleep(1)
        snap("16_Profile_Settings")

        // ── 11. My Orders ─────────────────────────────────────────────
        let ordersLink = app.staticTexts["My Orders"]
        if ordersLink.waitForExistence(timeout: 3) {
            ordersLink.tap()
            sleep(1)
            snap("17_Orders")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }

        // ── 12. Wishlist ──────────────────────────────────────────────
        let wishlistLink = app.staticTexts["Wishlist"]
        if wishlistLink.waitForExistence(timeout: 3) {
            wishlistLink.tap()
            sleep(1)
            snap("18_Wishlist")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }
    }

    // MARK: - Helper

    private func snap(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
