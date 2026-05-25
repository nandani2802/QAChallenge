import SwiftUI

@main
struct QAChallengeAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ShopViewModel())
        }
    }
}
