import Foundation

enum ProductCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case hardware = "Hardware"
    case accessories = "Accessories"
    case services = "Services"

    var id: String { rawValue }
}

struct Product: Identifiable, Equatable {
    let id: String
    let name: String
    let category: ProductCategory
    let price: Decimal
    let inStock: Bool
    let rating: Double
}

struct CartLine: Identifiable, Equatable {
    let product: Product
    var quantity: Int

    var id: String { product.id }
    var subtotal: Decimal { product.price * Decimal(quantity) }
}

struct CheckoutForm: Equatable {
    var fullName = ""
    var email = ""
    var zipCode = ""
    var acceptTerms = false
}

enum AppMode {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
    }

    static var useFastDelays: Bool {
        ProcessInfo.processInfo.arguments.contains("--fast-delays")
    }
}
