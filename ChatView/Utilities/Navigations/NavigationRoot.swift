import SwiftUI

/// Root navigation container that handles all navigation routing
struct NavigationRoot<Content: View>: View {
    @StateObject private var coordinator = NavigationCoordinator()
    @StateObject private var authVM = AuthViewModel()
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if authVM.isAuthenticated {
                // Authenticated: Show main app
                NavigationStack(path: $coordinator.path) {
                    content
                        .navigationDestination(for: Destination.self) { destination in
                            destinationView(for: destination)
                        }
                }
            } else {
                // Not authenticated: Show login
                NavigationStack(path: $coordinator.path) {
                    LoginView()
                        .navigationDestination(for: Destination.self) { destination in
                            destinationView(for: destination)
                        }
                }
            }
        }
        .environmentObject(coordinator)
        .environmentObject(authVM)
        .onChange(of: authVM.isAuthenticated) { isAuthenticated in
            // Clear navigation stack when auth state changes to ensure
            // we start fresh (e.g., remove SignupView when logging in,
            // or remove ChatDetailView when logging out)
            coordinator.popToRoot()
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: Destination) -> some View {
        switch destination {
        case .login:
            LoginView()
        case .signup:
            SignupView()
        case .chatDetail(let chat, let currentUser):
            ChatDetailView(vm: ChatViewModel(chat: chat, currentUser: currentUser))
        }
    }
}

