import Foundation
import SwiftUI

@MainActor
final class ShopViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var email = ""
    @Published var password = ""
    @Published var loginError: String?
    @Published var selectedCategory: ProductCategory = .all
    @Published var searchText = ""
    @Published var cart: [CartLine] = []
    @Published var promoCode = ""
    @Published var checkout = CheckoutForm()
    @Published var checkoutMessage: String?
    @Published var isLoadingInventory = false

    let products: [Product] = [
        Product(id: "prd-keyboard", name: "Aster Keyboard", category: .hardware, price: 129, inStock: true, rating: 4.7),
        Product(id: "prd-stand", name: "Focus Stand", category: .accessories, price: 48, inStock: true, rating: 4.5),
        Product(id: "prd-camera", name: "Orbit Camera", category: .hardware, price: 199, inStock: false, rating: 4.1),
        Product(id: "prd-plan", name: "Device Care Plan", category: .services, price: 29, inStock: true, rating: 4.3),
        Product(id: "prd-cable", name: "USB-C Travel Cable", category: .accessories, price: 18, inStock: true, rating: 4.8)
    ]

    init() {
        if AppMode.isUITesting {
            email = "qa@example.com"
            password = "Password123"
        }
    }

    var filteredProducts: [Product] {
        products.filter { product in
            let categoryMatches = selectedCategory == .all || product.category == selectedCategory
            let searchMatches = searchText.isEmpty || product.name.localizedCaseInsensitiveContains(searchText)
            return categoryMatches && searchMatches
        }
    }

    var cartTotal: Decimal {
        let base = cart.reduce(Decimal(0)) { $0 + $1.subtotal }
        return base - discount(for: base)
    }

    var itemCount: Int {
        cart.reduce(0) { $0 + $1.quantity }
    }

    var canSubmitCheckout: Bool {
        !checkout.fullName.isEmpty &&
            checkout.email.contains("@") &&
            checkout.zipCode.count == 5 &&
            checkout.acceptTerms &&
            !cart.isEmpty
    }

    func signIn() {
        loginError = nil

        guard email.localizedCaseInsensitiveCompare("qa@example.com") == .orderedSame,
              password == "Password123" else {
            loginError = "Use qa@example.com / Password123"
            return
        }

        isSignedIn = true
        Task { await refreshInventory() }
    }

    func signOut() {
        isSignedIn = false
        cart.removeAll()
        checkout = CheckoutForm()
        checkoutMessage = nil
    }

    func refreshInventory() async {
        isLoadingInventory = true
        let delay: UInt64 = AppMode.useFastDelays ? 100_000_000 : 900_000_000
        try? await Task.sleep(nanoseconds: delay)
        isLoadingInventory = false
    }

    func addToCart(_ product: Product) {
        guard product.inStock else { return }
        if let index = cart.firstIndex(where: { $0.product.id == product.id }) {
            cart[index].quantity += 1
        } else {
            cart.append(CartLine(product: product, quantity: 1))
        }
    }

    func removeFromCart(_ product: Product) {
        guard let index = cart.firstIndex(where: { $0.product.id == product.id }) else { return }

        if cart[index].quantity > 1 {
            cart[index].quantity -= 1
        } else {
            cart.remove(at: index)
        }
    }

    func submitCheckout() {
        guard canSubmitCheckout else {
            checkoutMessage = "Complete all checkout fields."
            return
        }

        checkoutMessage = "Order placed for \(checkout.fullName)."
        cart.removeAll()
    }

    func discount(for subtotal: Decimal) -> Decimal {
        guard promoCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "SAVE10" else {
            return 0
        }

        // Intentional challenge defect: the product spec says SAVE10 should apply 10%.
        return subtotal * Decimal(0.05)
    }
}

extension Decimal {
    var currencyText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: self as NSDecimalNumber) ?? "$0.00"
    }
}
