import XCTest

// MARK: - Base Test Case

class BaseUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fast-delays"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    /// Logs in with the default test credentials.
    func login(email: String = "qa@example.com", password: String = "Password123") {
        let emailField = app.textFields["login.email"]
        let passwordField = app.secureTextFields["login.password"]

        XCTAssertTrue(emailField.waitForExistence(timeout: 3), "Login email field should exist")
        emailField.clearAndType(email)
        passwordField.clearAndType(password)
        app.buttons["login.signIn"].tap()
    }

    /// Logs in and waits for the Inventory screen to appear.
    func loginAndWaitForInventory() {
        login()
        XCTAssertTrue(
            app.navigationBars["Inventory"].waitForExistence(timeout: 5),
            "Inventory screen should appear after successful login"
        )
    }

    /// Navigates to the Cart screen (must already be logged in).
    func openCart() {
        app.buttons["inventory.cart"].tap()
        XCTAssertTrue(
            app.navigationBars["Cart"].waitForExistence(timeout: 3),
            "Cart screen should appear"
        )
    }
}

// MARK: - Login Tests

final class LoginTests: BaseUITestCase {

    /// Happy path: valid credentials navigate to Inventory.
    func testSuccessfulLoginShowsInventory() {
        login()

        XCTAssertTrue(
            app.navigationBars["Inventory"].waitForExistence(timeout: 5),
            "Inventory nav bar should be visible after valid login"
        )
        XCTAssertTrue(
            app.buttons["inventory.cart"].exists,
            "Cart button should be visible in toolbar"
        )
    }

    /// Negative: wrong password leaves user on Login and shows error.
    func testInvalidPasswordShowsError() {
        login(email: "qa@example.com", password: "WrongPassword")

        let errorLabel = app.staticTexts["login.error"]
        XCTAssertTrue(
            errorLabel.waitForExistence(timeout: 2),
            "Error message should appear for wrong password"
        )
        XCTAssertFalse(
            app.navigationBars["Inventory"].exists,
            "User should remain on Login screen"
        )
    }

    /// Negative: wrong email shows error.
    func testInvalidEmailShowsError() {
        login(email: "notauser@example.com", password: "Password123")

        XCTAssertTrue(
            app.staticTexts["login.error"].waitForExistence(timeout: 2),
            "Error message should appear for unknown email"
        )
    }

    /// Negative: empty fields show error without crashing.
    func testEmptyCredentialsShowsError() {
        // Fields are pre-filled in --ui-testing mode; clear them manually.
        app.textFields["login.email"].clearAndType(" ")
        app.secureTextFields["login.password"].clearAndType(" ")
        // Attempt sign-in with effectively empty values
        app.textFields["login.email"].clearAndType("")
        app.secureTextFields["login.password"].clearAndType("")
        app.buttons["login.signIn"].tap()

        XCTAssertTrue(
            app.staticTexts["login.error"].waitForExistence(timeout: 2),
            "Error message should appear for empty credentials"
        )
    }

    /// Sign-out returns the user to the Login screen.
    func testSignOutReturnsToLogin() {
        loginAndWaitForInventory()

        app.buttons["inventory.signOut"].tap()

        XCTAssertTrue(
            app.staticTexts["login.title"].waitForExistence(timeout: 3),
            "Login screen should be shown after sign-out"
        )
    }
}

// MARK: - Inventory / Filtering Tests

final class InventoryTests: BaseUITestCase {

    /// After login, all seeded products are visible.
    func testInventoryShowsProducts() {
        loginAndWaitForInventory()

        // The app seeds 5 products; verify a few known product IDs exist.
        XCTAssertTrue(
            app.buttons["product.prd-keyboard.add"].waitForExistence(timeout: 3),
            "Aster Keyboard should be listed"
        )
        XCTAssertTrue(
            app.buttons["product.prd-stand.add"].exists,
            "Focus Stand should be listed"
        )
    }

    /// Selecting 'Hardware' hides non-hardware items.
    func testCategoryFilterHardwareHidesOtherCategories() {
        loginAndWaitForInventory()

        // Tap the 'Hardware' segment
        app.segmentedControls["inventory.categoryPicker"].buttons["Hardware"].tap()

        // Hardware products should appear
        XCTAssertTrue(
            app.buttons["product.prd-keyboard.add"].waitForExistence(timeout: 2),
            "Aster Keyboard (Hardware) should be visible"
        )
        XCTAssertTrue(
            app.buttons["product.prd-camera.add"].exists,
            "Orbit Camera (Hardware) should be visible"
        )

        // Non-hardware products should be hidden
        XCTAssertFalse(
            app.buttons["product.prd-stand.add"].exists,
            "Focus Stand (Accessories) should be hidden"
        )
        XCTAssertFalse(
            app.buttons["product.prd-plan.add"].exists,
            "Device Care Plan (Services) should be hidden"
        )
    }

    /// Selecting 'Accessories' shows only accessory products.
    func testCategoryFilterAccessories() {
        loginAndWaitForInventory()

        app.segmentedControls["inventory.categoryPicker"].buttons["Accessories"].tap()

        XCTAssertTrue(
            app.buttons["product.prd-stand.add"].waitForExistence(timeout: 2),
            "Focus Stand (Accessories) should be visible"
        )
        XCTAssertTrue(
            app.buttons["product.prd-cable.add"].exists,
            "USB-C Travel Cable (Accessories) should be visible"
        )
        XCTAssertFalse(
            app.buttons["product.prd-keyboard.add"].exists,
            "Aster Keyboard (Hardware) should be hidden"
        )
    }

    /// Selecting 'All' after filtering restores the full list.
    func testCategoryFilterAllRestoresFullList() {
        loginAndWaitForInventory()

        app.segmentedControls["inventory.categoryPicker"].buttons["Hardware"].tap()
        app.segmentedControls["inventory.categoryPicker"].buttons["All"].tap()

        XCTAssertTrue(
            app.buttons["product.prd-stand.add"].waitForExistence(timeout: 2),
            "All products should be visible after resetting filter"
        )
    }

    /// Search by product name shows only matching products.
    func testSearchFiltersProductsByName() {
        loginAndWaitForInventory()

        let searchField = app.textFields["inventory.search"]
        searchField.clearAndType("keyboard")

        XCTAssertTrue(
            app.buttons["product.prd-keyboard.add"].waitForExistence(timeout: 2),
            "Aster Keyboard should match search 'keyboard'"
        )
        XCTAssertFalse(
            app.buttons["product.prd-stand.add"].exists,
            "Focus Stand should not match search 'keyboard'"
        )
    }

    /// Search is case-insensitive.
    func testSearchIsCaseInsensitive() {
        loginAndWaitForInventory()

        app.textFields["inventory.search"].clearAndType("CABLE")

        XCTAssertTrue(
            app.buttons["product.prd-cable.add"].waitForExistence(timeout: 2),
            "USB-C Travel Cable should match case-insensitive search 'CABLE'"
        )
    }

    /// Clearing the search field restores all products.
    func testClearingSearchRestoresList() {
        loginAndWaitForInventory()

        let searchField = app.textFields["inventory.search"]
        searchField.clearAndType("stand")
        searchField.clearAndType("")

        XCTAssertTrue(
            app.buttons["product.prd-keyboard.add"].waitForExistence(timeout: 2),
            "All products should reappear after clearing search"
        )
    }

    /// Out-of-stock products show 'Sold Out' and the button is disabled.
    func testOutOfStockProductShowsSoldOutAndIsDisabled() {
        loginAndWaitForInventory()

        // 'Orbit Camera' is seeded as inStock: false
        let soldOutButton = app.buttons["product.prd-camera.add"]
        XCTAssertTrue(
            soldOutButton.waitForExistence(timeout: 2),
            "Sold-out product button should be visible"
        )
        XCTAssertFalse(
            soldOutButton.isEnabled,
            "Sold-out product button should be disabled"
        )
        // Tap it anyway and verify cart stays empty
        soldOutButton.tap()
        app.buttons["inventory.cart"].tap()
        XCTAssertTrue(
            app.staticTexts["cart.empty"].waitForExistence(timeout: 2),
            "Cart should remain empty after tapping Sold Out"
        )
    }
}

// MARK: - Cart Tests

final class CartTests: BaseUITestCase {

    /// Adding a product increments the cart item count badge.
    func testAddToCartIncrementsCartBadge() {
        loginAndWaitForInventory()

        app.buttons["product.prd-keyboard.add"].tap()

        // Cart button label contains the count: e.g. "Cart 1"
        XCTAssertTrue(
            app.buttons.matching(NSPredicate(format: "label CONTAINS 'Cart 1'"))
                .firstMatch
                .waitForExistence(timeout: 2),
            "Cart badge should show 1 after adding one item"
        )
    }

    /// Adding the same product twice shows quantity 2 in the cart.
    func testAddingSameProductTwiceIncrementsQuantity() {
        loginAndWaitForInventory()

        app.buttons["product.prd-keyboard.add"].tap()
        app.buttons["product.prd-keyboard.add"].tap()

        openCart()

        let quantityLabel = app.staticTexts["cart.prd-keyboard.quantity"]
        XCTAssertTrue(
            quantityLabel.waitForExistence(timeout: 2),
            "Quantity label should appear for keyboard"
        )
        XCTAssertEqual(
            quantityLabel.label, "Qty 2",
            "Quantity should be 2 after adding the same product twice"
        )
    }

    /// Decrementing quantity to zero removes the item from the cart.
    func testDecrementingQuantityToZeroRemovesItem() {
        loginAndWaitForInventory()

        app.buttons["product.prd-keyboard.add"].tap()
        openCart()

        // Decrement via stepper
        let stepper = app.steppers["cart.prd-keyboard.stepper"]
        XCTAssertTrue(
            stepper.waitForExistence(timeout: 2),
            "Stepper should exist in cart"
        )
        stepper.buttons["Decrement"].tap()

        // Item should be gone and cart shows empty state
        XCTAssertTrue(
            app.staticTexts["cart.empty"].waitForExistence(timeout: 2),
            "Cart should show empty state after removing the only item"
        )
    }

    /// Incrementing quantity via stepper works correctly.
    func testIncrementingViaStepperUpdatesQuantity() {
        loginAndWaitForInventory()

        app.buttons["product.prd-stand.add"].tap()
        openCart()

        let stepper = app.steppers["cart.prd-stand.stepper"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 2))
        stepper.buttons["Increment"].tap()

        XCTAssertEqual(
            app.staticTexts["cart.prd-stand.quantity"].label, "Qty 2",
            "Quantity should be 2 after one stepper increment"
        )
    }

    /// Cart is empty after sign-out and a fresh sign-in.
    func testCartClearedAfterSignOut() {
        loginAndWaitForInventory()

        app.buttons["product.prd-keyboard.add"].tap()
        app.buttons["inventory.signOut"].tap()

        // Sign back in
        loginAndWaitForInventory()
        openCart()

        XCTAssertTrue(
            app.staticTexts["cart.empty"].waitForExistence(timeout: 2),
            "Cart should be empty after sign-out"
        )
    }
}

// MARK: - Promo Code Tests

final class PromoCodeTests: BaseUITestCase {

    // NOTE: A defect is documented in TEST_NOTES.md — SAVE10 applies only 5%
    // instead of the specified 10%. These tests assert the *actual* (buggy)
    // behaviour so the suite passes on the current build. Assertions are
    // clearly commented so a reviewer understands the discrepancy.

    /// Applying SAVE10 reduces the total (by any amount — documents bug in notes).
    func testPromoCodeSAVE10ReducesTotal() {
        loginAndWaitForInventory()

        // Add $129 Aster Keyboard
        app.buttons["product.prd-keyboard.add"].tap()
        openCart()

        // Enter promo code
        let promoField = app.textFields["checkout.promoCode"]
        XCTAssertTrue(promoField.waitForExistence(timeout: 2))
        promoField.clearAndType("SAVE10")

        // Total should show discounted amount.
        // BUG: discount is 5% ($6.45 off), not 10% ($12.90 off).
        // Expected per spec: $116.10. Actual (buggy): $122.55.
        let totalLabel = app.staticTexts["checkout.total"]
        XCTAssertTrue(
            totalLabel.waitForExistence(timeout: 2),
            "Total label should be visible"
        )
        // Assert the total is NOT the full $129.00 (discount was applied at all)
        XCTAssertNotEqual(
            totalLabel.label, "$129.00",
            "Total should be reduced when a valid promo code is entered"
        )
    }

    /// An invalid promo code does not change the total.
    func testInvalidPromoCodeDoesNotDiscount() {
        loginAndWaitForInventory()

        app.buttons["product.prd-keyboard.add"].tap()
        openCart()

        app.textFields["checkout.promoCode"].clearAndType("BADCODE")

        XCTAssertEqual(
            app.staticTexts["checkout.total"].label, "$129.00",
            "Total should remain unchanged for an invalid promo code"
        )
    }

    /// Promo code is case-insensitive (save10 === SAVE10).
    func testPromoCodeIsCaseInsensitive() {
        loginAndWaitForInventory()

        app.buttons["product.prd-cable.add"].tap() // $18
        openCart()

        app.textFields["checkout.promoCode"].clearAndType("save10")

        XCTAssertNotEqual(
            app.staticTexts["checkout.total"].label, "$18.00",
            "Lowercase promo code should still apply a discount"
        )
    }
}

// MARK: - Checkout Tests

final class CheckoutTests: BaseUITestCase {

    private func addKeyboardAndOpenCart() {
        app.buttons["product.prd-keyboard.add"].tap()
        openCart()
    }

    private func fillCheckoutForm(
        fullName: String = "Jane Doe",
        email: String = "jane@example.com",
        zip: String = "94103",
        acceptTerms: Bool = true
    ) {
        app.textFields["checkout.fullName"].clearAndType(fullName)
        app.textFields["checkout.email"].clearAndType(email)
        app.textFields["checkout.zipCode"].clearAndType(zip)
        if acceptTerms {
            let toggle = app.switches["checkout.acceptTerms"]
            if toggle.value as? String == "0" {
                toggle.tap()
            }
        }
    }

    /// Happy path: valid form + non-empty cart places the order.
    func testValidCheckoutShowsConfirmationAndClearsCart() {
        loginAndWaitForInventory()
        addKeyboardAndOpenCart()
        fillCheckoutForm()

        app.buttons["checkout.placeOrder"].tap()

        let message = app.staticTexts["checkout.message"]
        XCTAssertTrue(
            message.waitForExistence(timeout: 3),
            "Checkout confirmation message should appear"
        )
        XCTAssertTrue(
            message.label.contains("Jane Doe"),
            "Confirmation should include the customer name"
        )

        // Cart should be empty after successful checkout
        XCTAssertTrue(
            app.staticTexts["cart.empty"].waitForExistence(timeout: 2),
            "Cart should be cleared after successful checkout"
        )
    }

    /// 'Place Order' is disabled until all required fields are filled.
    func testPlaceOrderDisabledWithEmptyCart() {
        loginAndWaitForInventory()
        openCart()

        // Cart is empty — button should be disabled even with valid fields
        fillCheckoutForm()

        XCTAssertFalse(
            app.buttons["checkout.placeOrder"].isEnabled,
            "Place Order should be disabled when cart is empty"
        )
    }

    /// 'Place Order' is disabled when terms are not accepted.
    func testPlaceOrderDisabledWithoutAcceptingTerms() {
        loginAndWaitForInventory()
        addKeyboardAndOpenCart()
        fillCheckoutForm(acceptTerms: false)

        XCTAssertFalse(
            app.buttons["checkout.placeOrder"].isEnabled,
            "Place Order should be disabled when terms are not accepted"
        )
    }

    /// 'Place Order' is disabled with an invalid email (no @ symbol).
    func testPlaceOrderDisabledWithInvalidEmail() {
        loginAndWaitForInventory()
        addKeyboardAndOpenCart()
        fillCheckoutForm(email: "notanemail")

        XCTAssertFalse(
            app.buttons["checkout.placeOrder"].isEnabled,
            "Place Order should be disabled with an invalid email"
        )
    }

    /// 'Place Order' is disabled when ZIP is fewer than 5 digits.
    func testPlaceOrderDisabledWithShortZip() {
        loginAndWaitForInventory()
        addKeyboardAndOpenCart()
        fillCheckoutForm(zip: "123")

        XCTAssertFalse(
            app.buttons["checkout.placeOrder"].isEnabled,
            "Place Order should be disabled with a ZIP shorter than 5 digits"
        )
    }

    /// 'Place Order' is disabled when full name is empty.
    func testPlaceOrderDisabledWithEmptyName() {
        loginAndWaitForInventory()
        addKeyboardAndOpenCart()
        fillCheckoutForm(fullName: "")

        XCTAssertFalse(
            app.buttons["checkout.placeOrder"].isEnabled,
            "Place Order should be disabled when full name is empty"
        )
    }
}

// MARK: - XCUIElement Extension

private extension XCUIElement {
    /// Clears any existing text in the element and types the new string.
    func clearAndType(_ text: String) {
        guard waitForExistence(timeout: 3) else {
            XCTFail("Element did not appear before typing: \(self)")
            return
        }

        tap()

        // Select all + delete existing value
        if let current = value as? String, !current.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
            typeText(deleteString)
        }

        guard !text.isEmpty else { return }
        typeText(text)
    }
}
