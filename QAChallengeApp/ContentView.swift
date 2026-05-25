import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ShopViewModel

    var body: some View {
        NavigationStack {
            if viewModel.isSignedIn {
                ProductListView(viewModel: viewModel)
            } else {
                LoginView(viewModel: viewModel)
            }
        }
    }
}

struct LoginView: View {
    @ObservedObject var viewModel: ShopViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("QA Shop")
                .font(.largeTitle.bold())
                .accessibilityIdentifier("login.title")

            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("login.email")

            SecureField("Password", text: $viewModel.password)
                .textContentType(.password)
                .accessibilityIdentifier("login.password")

            if let loginError = viewModel.loginError {
                Text(loginError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("login.error")
            }

            Button("Sign In") {
                viewModel.signIn()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("login.signIn")
        }
        .textFieldStyle(.roundedBorder)
        .padding(24)
    }
}

struct ProductListView: View {
    @ObservedObject var viewModel: ShopViewModel

    var body: some View {
        List {
            Section {
                Picker("Category", selection: $viewModel.selectedCategory) {
                    ForEach(ProductCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("inventory.categoryPicker")

                TextField("Search products", text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("inventory.search")
            }

            if viewModel.isLoadingInventory {
                ProgressView("Refreshing inventory")
                    .accessibilityIdentifier("inventory.loading")
            }

            Section("Products") {
                ForEach(viewModel.filteredProducts) { product in
                    ProductRow(product: product) {
                        viewModel.addToCart(product)
                    }
                }
            }
        }
        .navigationTitle("Inventory")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Sign Out") {
                    viewModel.signOut()
                }
                .accessibilityIdentifier("inventory.signOut")
            }

            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CartView(viewModel: viewModel)
                } label: {
                    Text("Cart \(viewModel.itemCount)")
                }
                .accessibilityIdentifier("inventory.cart")
            }
        }
    }
}

struct ProductRow: View {
    let product: Product
    let addAction: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .accessibilityIdentifier("product.\(product.id).name")
                Text("\(product.category.rawValue) - Rating \(product.rating, specifier: "%.1f")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(product.price.currencyText)
                    .font(.subheadline.bold())
                    .accessibilityIdentifier("product.\(product.id).price")
            }

            Spacer()

            Button(product.inStock ? "Add" : "Sold Out", action: addAction)
                .buttonStyle(.bordered)
                .disabled(!product.inStock)
                .accessibilityIdentifier("product.\(product.id).add")
        }
        .accessibilityElement(children: .contain)
    }
}

struct CartView: View {
    @ObservedObject var viewModel: ShopViewModel

    var body: some View {
        Form {
            Section("Cart") {
                if viewModel.cart.isEmpty {
                    Text("Your cart is empty.")
                        .accessibilityIdentifier("cart.empty")
                }

                ForEach(viewModel.cart) { line in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(line.product.name)
                            Text("Qty \(line.quantity)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("cart.\(line.product.id).quantity")
                        }
                        Spacer()
                        Text(line.subtotal.currencyText)
                        Stepper("Quantity", onIncrement: {
                            viewModel.addToCart(line.product)
                        }, onDecrement: {
                            viewModel.removeFromCart(line.product)
                        })
                        .labelsHidden()
                        .accessibilityIdentifier("cart.\(line.product.id).stepper")
                    }
                }
            }

            Section("Promo") {
                TextField("Promo code", text: $viewModel.promoCode)
                    .textInputAutocapitalization(.characters)
                    .accessibilityIdentifier("checkout.promoCode")

                Text("Total \(viewModel.cartTotal.currencyText)")
                    .font(.headline)
                    .accessibilityIdentifier("checkout.total")
            }

            Section("Checkout") {
                TextField("Full name", text: $viewModel.checkout.fullName)
                    .textContentType(.name)
                    .accessibilityIdentifier("checkout.fullName")

                TextField("Email", text: $viewModel.checkout.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("checkout.email")

                TextField("ZIP code", text: $viewModel.checkout.zipCode)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("checkout.zipCode")

                Toggle("Accept terms", isOn: $viewModel.checkout.acceptTerms)
                    .accessibilityIdentifier("checkout.acceptTerms")

                Button("Place Order") {
                    viewModel.submitCheckout()
                }
                .disabled(!viewModel.canSubmitCheckout)
                .accessibilityIdentifier("checkout.placeOrder")

                if let checkoutMessage = viewModel.checkoutMessage {
                    Text(checkoutMessage)
                        .accessibilityIdentifier("checkout.message")
                }
            }
        }
        .navigationTitle("Cart")
    }
}

#Preview {
    ContentView(viewModel: ShopViewModel())
}
