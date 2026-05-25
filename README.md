# iOS QA Automation Technical Challenge

## Goal

Build an automated test suite for a small SwiftUI shopping app. The app is intentionally compact, but it includes real test surfaces: login, async loading, filtering, cart management, promo code calculation, and checkout validation.

## Timebox

Ask candidates to spend 90-120 minutes. They do not need to automate every path. A strong submission should show stable automation design, clear assertions, good failure output, and pragmatic coverage choices.

## App Credentials

- Email: `qa@example.com`
- Password: `Password123`
- Promo code: `SAVE10`

## Candidate Tasks

1. Clone or open the project in Xcode.
2. Run the app and existing UI tests.
3. Add UI automation coverage for the highest-risk user flows.
4. Document any defects, testability gaps, flaky areas, or product questions.
5. Keep the solution maintainable enough that another QA engineer could extend it.

## Functional Requirements

- Valid credentials should sign the user in and show the inventory screen.
- Invalid credentials should show a helpful error and keep the user on login.
- Product category filtering should show only products in the selected category.
- Search should filter products by name.
- Out-of-stock products should not be addable to the cart.
- Adding the same product multiple times should increase quantity.
- Removing quantity to zero should remove the item.
- Promo code `SAVE10` should discount the cart subtotal by 10%.
- Checkout should require full name, valid email, five-digit ZIP, accepted terms, and a non-empty cart.
- A valid checkout should show confirmation and empty the cart.

## Automation Requirements

- Use XCTest/XCUITest.
- Prefer accessibility identifiers over positional queries.
- Use deterministic launch arguments: `--ui-testing --fast-delays`.
- Avoid fixed sleeps unless there is a clear justification.
- Include both happy-path and negative-path coverage.
- Add brief notes explaining what you chose not to test and why.

## What To Submit

- Updated test code.
- A short `TEST_NOTES.md` covering:
  - Tested scenarios.
  - Defects found.
  - Flake risks.
  - Suggested app testability improvements.


## About the project

A compact SwiftUI iOS app for evaluating QA candidates with iOS automation experience.

The challenge app includes:

- Login with deterministic test credentials.
- Inventory list with category filter and search.
- Cart quantity updates.
- Promo code and checkout validation.
- Starter XCUITest suite.
- Candidate and evaluator challenge docs in `Challenge/`.

## Open In Xcode

Open `QAChallengeApp.xcodeproj`, select an iPhone simulator, then run the `QAChallengeAppUITests` target.

The provided UI tests launch the app with:

```text
--ui-testing --fast-delays
```

These arguments seed credentials and shorten the simulated inventory refresh delay.
